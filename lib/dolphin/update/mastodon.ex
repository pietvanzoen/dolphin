defmodule Dolphin.Update.Mastodon do
  defstruct [:content, :in_reply_to_id, :reply]
  alias Dolphin.{Update, Update.Split}

  @mastodon Application.get_env(:dolphin, :mastodon, Hunter)
  @http_client Application.get_env(:dolphin, :http_client, HTTPoison)
  @credentials Application.get_env(:dolphin, :mastodon_credentials)
  @base_url @credentials[:base_url]
  @conn Hunter.new(@credentials)
  @github_username Application.get_env(:dolphin, :github_credentials)[:username]
  @github_repository Application.get_env(:dolphin, :github_credentials)[:repository]

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Mastodon{})
  end

  defp from_update(
         %Update{in_reply_to: "#{@base_url}/web/statuses/" <> in_reply_to_id} = update,
         acc
       ) do
    from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})
  end

  defp from_update(%Update{in_reply_to: "/" <> path}, acc) do
    repo_path =
      path
      |> String.replace("/", "-")
      |> String.replace_trailing(".html", ".md")

    {:ok, %HTTPoison.Response{body: body}} =
      @http_client.get(
        "https://raw.githubusercontent.com/#{@github_username}/#{@github_repository}/master/" <>
          repo_path
      )

    {:ok, %{"mastodon" => urls}, _} = FrontMatter.decode(body)
    from_update(%Update{in_reply_to: List.last(urls)}, acc)
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) and url != "" do
    case @mastodon.search(@conn, url) do
      %{statuses: [%{id: in_reply_to_id} | _]} ->
        from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})

      _ ->
        {:error, :invalid_in_reply_to}
    end
  end

  defp from_update(%Update{text: text}, acc) do
    case validate_mentions(text) do
      :ok ->
        update =
          text
          |> Smarty.convert!()
          |> Update.replace_markdown_links()
          |> Split.split(500)
          |> from_splits(acc)

        {:ok, update}

      {:error, _} = error ->
        error
    end
  end

  defp from_splits(splits, update \\ %Dolphin.Update.Mastodon{})

  defp from_splits([content | tail], update) do
    %{update | content: content, reply: from_splits(tail)}
  end

  defp from_splits([], _update), do: nil

  def post(%Dolphin.Update.Mastodon{reply: reply} = update) do
    %{id: id, url: url} = do_post(update)

    reply_urls =
      case reply do
        %Dolphin.Update.Mastodon{} ->
          {:ok, urls} = post(%{reply | in_reply_to_id: id})
          urls

        _ ->
          []
      end

    {:ok, [url] ++ reply_urls}
  end

  def post(%Update{} = update) do
    case from_update(update) do
      {:ok, update} -> post(update)
      {:error, _} = error -> error
    end
  end

  defp do_post(%Dolphin.Update.Mastodon{content: content, in_reply_to_id: in_reply_to_id})
       when in_reply_to_id != nil do
    @mastodon.create_status(@conn, content, in_reply_to_id: in_reply_to_id)
  end

  defp do_post(%Dolphin.Update.Mastodon{content: content}) do
    @mastodon.create_status(@conn, content)
  end

  defp validate_mentions(text) do
    if(Regex.match?(~r/\@.+@twitter.com/, text)) do
      {:error, :invalid_mention}
    else
      :ok
    end
  end
end
