defmodule Uryi.Session do
  @moduledoc false
  use GenServer
  require Logger

  @type state :: %{client_id: pos_integer(), auth: atom()}

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_opts) do
    Uryi.PubSub.subscribe(Uryi.bot_topic())
    Uryi.PubSub.subscribe(Uryi.td_topic())
    {:ok, %{client_id: 1, auth: nil}}
  end

  @impl true
  def handle_info({TD.Poller, message}, state) do
    state = td_handle(message, state)
    {:noreply, state}
  end

  def handle_info({Bot.Poller, message}, state) do
    owner_id = Uryi.owner_id()

    case message do
      %{"message" => %{"chat" => %{"id" => ^owner_id}, "text" => text}} ->
        bot_handle(text, state)

      _other ->
        Logger.debug(bot: message)
    end

    {:noreply, state}
  end

  @spec td_handle(map, state) :: state
  defp td_handle(
         %{
           "@type" => "updateAuthorizationState",
           "authorization_state" => %{"@type" => type},
           "@client_id" => client_id
         },
         state
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

        %{state | client_id: client_id}

      "authorizationStateWaitPhoneNumber" ->
        prompt_phone()
        %{state | auth: :phone}

      "authorizationStateWaitCode" ->
        prompt_phone()
        %{state | auth: :code}

      "authorizationStateWaitPassword" ->
        prompt_phone()
        %{state | auth: :password}
    end
  end

  defp td_handle(
         %{"@client_id" => client_id, "@type" => "error", "@extra" => extra} = message,
         state
       ) do
    Logger.error(tdlib: message)

    case extra do
      "AUTH_PHONE" -> prompt_phone()
      "AUTH_CODE" -> prompt_code()
      "AUTH_PASSWORD" -> prompt_password()
    end

    state
  end

  defp td_handle(%{"@type" => "error"} = message, state) do
    Logger.error(tdlib: message)
    state
  end

  defp td_handle(%{"@type" => "updateOption"} = message, state) do
    case message do
      %{"name" => "version", "value" => %{"value" => version}} ->
        Uryi.put_env(:td_version, version)

      %{"name" => "commit_hash", "value" => %{"value" => commit}} ->
        Uryi.put_env(:td_commit, commit)

      _ ->
        Logger.debug(skipped: true, tdlib: message)
    end

    state
  end

  defp td_handle(message, state) do
    Logger.debug(skipped: true, tdlib: message)
    state
  end

  defp prompt_phone do
    {:ok, _} = Bot.send_prompt(Uryi.owner_id(), "Please enter your phone number")
  end

  defp prompt_code do
    {:ok, _} =
      Bot.send_prompt(Uryi.owner_id(), "Please enter the authentication code you received")
  end

  defp prompt_password do
    {:ok, _} = Bot.send_prompt(Uryi.owner_id(), "Please enter your password")
  end

  def set_phone(client_id, text) do
    TD.send(client_id, %{
      "@type" => "setAuthenticationPhoneNumber",
      "@extra" => "AUTH_PHONE",
      "phone_number" => text
    })
  end

  def check_code(client_id, text) do
    TD.send(client_id, %{
      "@type" => "checkAuthenticationCode",
      "@extra" => "AUTH_CODE",
      "code" => String.to_integer(text)
    })
  end

  def check_password(client_id, text) do
    TD.send(client_id, %{
      "@type" => "checkAuthenticationPassword",
      "@extra" => "AUTH_PASSWORD",
      "password" => text
    })
  end

  defp bot_handle(text, %{auth: auth, client_id: client_id}) when not is_nil(auth) do
    case auth do
      :phone -> set_phone(client_id, text)
      :code -> check_code(client_id, text)
      :password -> check_password(client_id, text)
    end
  end
end
