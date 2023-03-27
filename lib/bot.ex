defmodule Bot do
  @moduledoc "Telegram bot to configure and manage Uryi"
  require Logger
  alias Bot.{API, Waiter, Poller}

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :supervisor}
  end

  def start_link(_opts) do
    children = [Waiter, {Poller, handler: Waiter}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  # https://core.telegram.org/bots/api#sendmessage
  def send_message(chat_id, text, opts \\ []) do
    payload = Enum.into(opts, %{"chat_id" => chat_id, "text" => text})
    API.request("sendMessage", payload)
  end

  def send_prompt(chat_id, text) do
    opts = %{"reply_markup" => %{"force_reply" => true}}

    with {:ok, %Finch.Response{status: 200, body: body}} <- send_message(chat_id, text, opts) do
      %{"ok" => true, "result" => %{"message_id" => message_id}} = Jason.decode!(body)
      {:ok, Waiter.wait_reply(chat_id, message_id, :infinity)}
    end
  end
end
