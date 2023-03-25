defmodule Uryi.Session do
  @moduledoc false
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    Uryi.PubSub.subscribe(Uryi.bot_topic())
    Uryi.PubSub.subscribe(Uryi.td_topic())
    {:ok, %{}}
  end

  @impl true
  def handle_info({TD, message}, state) do
  end

  @impl TD
  def td_handle(
        %{
          "@type" => "updateAuthorizationState",
          "authorization_state" => %{"@type" => type},
          "@client_id" => client_id
        },
        client_id
      ) do
    case type do
      "authorizationStateWaitTdlibParameters" ->
        TD.send(client_id, %{
          "@type" => "setTdlibParameters",
          "database_directory" => Uryi.td_database_directory(),
          "use_message_database" => true,
          "use_secret_chats" => false,
          "api_id" => Uryi.td_api_id(),
          "api_hash" => Uryi.td_api_hash(),
          "system_language_code" => "en",
          "device_model" => "basement",
          "application_version" => "0.1.0",
          "enable_storage_optimizer" => true,
          "use_test_dc" => Uryi.td_use_test_dc()
        })

      "authorizationStateWaitPhoneNumber" ->
        login_phone(client_id)

      "authorizationStateWaitCode" ->
        login_code(client_id)

      "authorizationStateWaitPassword" ->
        login_password(client_id)
    end
  end

  def td_handle(
        %{"@client_id" => client_id, "@type" => "error", "@extra" => extra} = message,
        client_id
      ) do
    Logger.error(tdlib: message, client_id: client_id)

    case extra do
      "AUTH_PHONE" -> login_phone(client_id)
      "AUTH_CODE" -> login_code(client_id)
      "AUTH_PASSWORD" -> login_password(client_id)
    end
  end

  def td_handle(%{"@type" => "error"} = message, client_id) do
    Logger.error(tdlib: message, client_id: client_id)
  end

  def td_handle(
        %{"@type" => "updateOption", "@client_id" => client_id} = message,
        client_id
      ) do
    case message do
      %{"name" => "version", "value" => %{"value" => version}} ->
        Uryi.put_env(:td_version, version)

      %{"name" => "commit_hash", "value" => %{"value" => commit}} ->
        Uryi.put_env(:td_commit, commit)

      _ ->
        Logger.debug(skipped: true, tdlib: message, client_id: client_id)
    end
  end

  def td_handle(message, client_id) do
    Logger.debug(skipped: true, tdlib: message, client_id: client_id)
  end

  @spec bot_prompt(String.t()) :: map
  def bot_prompt(prompt) do
    {:ok, %Finch.Response{status: 200, body: body}} = Bot.send_prompt(Uryi.owner_id(), prompt)

    %{"ok" => true, "result" => %{"message_id" => message_id}} =
      Jason.decode!(body) |> IO.inspect(label: "prompt")

    Bot.wait_message(Uryi.owner_id(), message_id + 1)
  end

  def login_phone(client_id) do
    %{"message" => %{"text" => phone}} = bot_prompt("Please enter your phone number")

    TD.send(client_id, %{
      "@type" => "setAuthenticationPhoneNumber",
      "@extra" => "AUTH_PHONE",
      "phone_number" => phone
    })
  end

  def login_code(client_id) do
    %{"message" => %{"text" => code}} =
      bot_prompt("Please enter the authentication code you received")

    TD.send(client_id, %{
      "@type" => "checkAuthenticationCode",
      "@extra" => "AUTH_CODE",
      "code" => String.to_integer(code)
    })
  end

  def login_password(client_id) do
    %{"message" => %{"text" => password}} = bot_prompt("Please enter your password")

    TD.send(client_id, %{
      "@type" => "checkAuthenticationPassword",
      "@extra" => "AUTH_PASSWORD",
      "password" => password
    })
  end
end
