defmodule Uryi do
  @moduledoc "ChatGPT over Telegram secretary"
  @app :uryi
  @behaviour TD.Session

  @doc false
  def finch, do: __MODULE__.Finch
  def fetch_env!(key), do: Application.fetch_env!(@app, key)
  def put_env(key, value), do: Application.put_env(@app, key, value)

  env_keys = [
    :enabled_in,
    :td_database_directory,
    :td_api_id,
    :td_api_hash,
    :td_use_test_dc,
    :openai_api_key,
    :gpt_model,
    :gpt_prompt
  ]

  for key <- env_keys do
    def unquote(key)(), do: Application.fetch_env!(@app, unquote(key))
  end

  def login do
    %{"authorization_state" => %{"@type" => type}} = auth_state()

    result =
      case type do
        "authorizationStateWaitPhoneNumber" ->
          {:cont, auth_phone(prompt("Please enter your phone number: "))}

        "authorizationStateWaitCode" ->
          {:cont, auth_code(prompt("Please enter the authentication code you received: "))}

        "authorizationStateWaitPassword" ->
          {:cont, auth_password(prompt("Please enter your password: "))}

        "authorizationStateReady" ->
          IO.puts("#{IO.ANSI.green()}You are logged in :)#{IO.ANSI.reset()}")
      end

    with {:cont, result} <- result do
      case result do
        %{"@type" => "ok"} ->
          :timer.sleep(100)

        %{"@type" => "error", "message" => message} ->
          IO.puts("#{IO.ANSI.red()}#{message}#{IO.ANSI.reset()}")
      end

      login()
    end
  end

  defp prompt(prompt) do
    prompt |> IO.gets() |> String.trim()
  end

  def auth_state, do: TD.Session.auth()
  def auth_phone(phone), do: TD.set_authentication_phone_number(phone)
  def auth_code(code), do: TD.check_authentication_code(code)
  def auth_password(password), do: TD.check_authentication_password(password)

  # TODO move to TD.Session
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
