defmodule Bot.Waiter do
  @moduledoc "Waits for reply messages from `#{Bot.Poller}`"
  use GenServer
  @behaviour Bot.Poller

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def wait_reply(chat_id, message_id, timeout) do
    GenServer.call(__MODULE__, {:wait_reply, {chat_id, message_id}}, timeout)
  end

  @impl true
  def handle_message(%{
        "message" => %{
          "chat" => %{"id" => chat_id},
          "from" => %{"id" => chat_id},
          "reply_to_message" => %{"message_id" => message_id},
          "text" => text
        }
      }) do
    GenServer.cast(__MODULE__, {:reply, {chat_id, message_id}, text})
  end

  def handle_message(_message) do
    :ignore
  end

  @impl true
  def init(_opts) do
    {:ok, _awaited = %{}}
  end

  @impl true
  def handle_call({:wait_reply, chat_message_id}, from, awaited) do
    {:noreply, Map.put(awaited, chat_message_id, from)}
  end

  @impl true
  def handle_cast({:reply, chat_message_id, message}, awaited) do
    {from, awaited} = Map.pop(awaited, chat_message_id)
    if from, do: GenServer.reply(from, message)
    {:noreply, awaited}
  end
end
