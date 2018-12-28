defmodule FakeTwitter do
  def start_link() do
    Agent.start_link(fn -> %{updates: []} end, name: __MODULE__)
  end

  def updates do
    Agent.get(__MODULE__, &Map.get(&1, :updates))
  end

  def update(status) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, fn %{updates: updates} = state ->
        %{state | updates: [status | updates]}
      end)
    end

    %{id: id(status), text: status}
  end

  def update(status, in_reply_to_status_id: in_reply_to_id) do
    %{id: id(status), text: status, in_reply_to_status_id: in_reply_to_id}
  end

  defp id(status) do
    sum =
      status
      |> to_charlist
      |> Enum.sum()

    10000 + sum
  end
end