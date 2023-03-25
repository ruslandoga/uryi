defmodule Bot do
  @moduledoc "Telegram bot to configure and manage Uryi"

  require Logger
  alias Bot.API

  # https://core.telegram.org/bots/api#sendmessage
  def send_message(chat_id, text, opts \\ []) do
    payload = Enum.into(opts, %{"chat_id" => chat_id, "text" => text})
    API.request("sendMessage", payload)
  end

  def send_silent_message(chat_id, text) do
    send_message(chat_id, text, %{"disable_notification" => true})
  end

  def send_prompt(chat_id, text) do
    send_message(chat_id, text, %{"reply_markup" => %{"force_reply" => true}})
  end
end
