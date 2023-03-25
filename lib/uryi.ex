defmodule Uryi do
  @moduledoc "ChatGPT over Telegram secretary"
  @app :uryi
  @behaviour TD.Session

  @doc false
  def finch, do: __MODULE__.Finch
  def bot_topic, do: "bot"
  def td_topic, do: "td"
  def fetch_env!(key), do: Application.fetch_env!(@app, key)
  def put_env(key, value), do: Application.put_env(@app, key, value)

  env_keys = [
    :owner_id,
    :enabled_in,
    :td_database_directory,
    :td_api_id,
    :td_api_hash,
    :td_use_test_dc,
    :tg_bot_token,
    :tg_bot_env,
    :openai_api_key,
    :gpt_model,
    :gpt_prompt
  ]

  for key <- env_keys do
    def unquote(key)(), do: Application.fetch_env!(@app, unquote(key))
  end

  @impl true
  def td_auth(
        %{"authorization_state" => %{"@type" => "authorizationStateWaitPhoneNumber"}} = event
      ) do
    {:ok, phone} = bot_prompt("Please enter your phone number")

    case TD.set_authentication_phone_number(phone) do
      %{"@type" => "ok"} -> :ok
      %{"@type" => "error"} -> td_auth(event)
    end
  end

  def td_auth(
        %{
          "@type" => "updateAuthorizationState",
          "authorization_state" => %{"@type" => "authorizationStateWaitCode"}
        } = event
      ) do
    {:ok, code} = bot_prompt("Please enter the authentication code you received")

    case TD.check_authentication_code(code) do
      %{"@type" => "ok"} -> :ok
      %{"@type" => "error"} -> td_auth(event)
    end
  end

  def td_auth(
        %{
          "@type" => "updateAuthorizationState",
          "authorization_state" => %{"@type" => "authorizationStateWaitPassword"}
        } = event
      ) do
    {:ok, password} = bot_prompt("Please enter your password")

    case TD.check_authentication_password(password) do
      %{"@type" => "ok"} -> :ok
      %{"@type" => "error"} -> td_auth(event)
    end
  end

  defp bot_prompt(text) do
    Bot.send_prompt(Uryi.owner_id(), text)
  end

  @impl true
  def td_new_message(%{
        "message" => %{
          "content" => %{"text" => %{"text" => text}},
          "chat_id" => chat_id,
          "is_outgoing" => is_outgoing
        }
      }) do
    should_reply? =
      chat_id in Uryi.enabled_in() and
        (!is_outgoing or String.contains?(text, "uryi"))

    if should_reply?, do: reply(chat_id, text)
  end

  def td_new_message(_event), do: :ignore

  def reply(chat_id, text) do
    with {:ok, content} <- GPT.chat_completion(text) do
      TD.send_message(chat_id, content)
    end

    # GPT.stream_chat_completion(text, fn
    #   {:done, {message_id, _} ->
    #     %{"@type" => "message"} = TD.edit_message_text(chat_id, message_id, text)

    #   text, nil ->
    #     %{"@type" => "message", "id" => message_id} = TD.send_message(chat_id, text)
    #     {message_id, System.monotonic_time(:millisecond)}

    #   text, {message_id, prev_time} = acc ->
    #     now = System.monotonic_time(:millisecond)
    #     elapsed = now - prev_time

    #     if elapsed > 500 do
    #       %{"@type" => "message"} = TD.edit_message_text(chat_id, message_id, text)
    #       {message_id, now}
    #     else
    #       acc
    #     end
    # end)
  end
end
