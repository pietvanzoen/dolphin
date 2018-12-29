defmodule Dolphin.Update.Mastodon do
  defstruct [:content, :in_reply_to_id]
  alias Dolphin.Update

  @mastodon Application.get_env(:dolphin, :mastodon, Hunter)
  @credentials Application.get_env(:dolphin, :mastodon_credentials)
  @base_url @credentials[:base_url]
  @conn Hunter.new(@credentials)

  def from_update(%Update{} = update) do
    from_update(update, %Dolphin.Update.Mastodon{})
  end

  defp from_update(
         %Update{in_reply_to: "#{@base_url}/web/statuses/" <> in_reply_to_id} = update,
         acc
       ) do
    from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})
  end

  defp from_update(%Update{in_reply_to: url} = update, acc) when is_binary(url) and url != "" do
    %{statuses: [%{id: in_reply_to_id} | _]} = @mastodon.search(@conn, url)

    from_update(Map.drop(update, [:in_reply_to]), %{acc | in_reply_to_id: in_reply_to_id})
  end

  defp from_update(%Update{text: text}, acc) do
    %{acc | content: text}
  end

  def post(%Dolphin.Update.Mastodon{content: content, in_reply_to_id: in_reply_to_id})
      when is_binary(in_reply_to_id) do
    %{url: url} = @mastodon.create_status(@conn, content, in_reply_to_status_id: in_reply_to_id)

    {:ok, [url]}
  end

  def post(%Dolphin.Update.Mastodon{content: content}) do
    %{url: url} = @mastodon.create_status(@conn, content)

    {:ok, [url]}
  end

  def post(%Update{} = update) do
    update
    |> from_update
    |> post
  end
end