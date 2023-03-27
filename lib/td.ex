defmodule TD do
  @moduledoc "TDLib client to allow Uryi hijack an account"
  import Kernel, except: [send: 2]
  alias TD.{Nif, Session, Poller}

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}, type: :supervisor}
  end

  def start_link(opts) do
    children = [{Poller, handler: Session}, {Session, opts}]
    Supervisor.start_link(children, strategy: :one_for_one)
  end

  def send(client_id, request) when is_map(request) do
    Nif.send(client_id, Jason.encode_to_iodata!(request))
  end

  def send_wait(request, timeout \\ :timer.seconds(5)) when is_map(request) do
    extra = System.unique_integer()
    request = Map.put(request, "@extra", extra)
    client_id = Session.client_id()
    send(client_id, request)
    Session.await(extra, timeout)
  end

  def execute(request) when is_map(request) do
    request |> Jason.encode_to_iodata!() |> Nif.execute() |> Jason.decode!()
  end

  def set_tdlib_parameters(client_id, overrides \\ []) do
    req = %{
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
    }

    req = Enum.into(overrides, req)
    send(client_id, req)
  end

  def set_authentication_phone_number(text) do
    send_wait(%{"@type" => "setAuthenticationPhoneNumber", "phone_number" => text})
  end

  def check_authentication_code(text) do
    send_wait(%{"@type" => "checkAuthenticationCode", "code" => text})
  end

  def check_authentication_password(text) do
    send_wait(%{"@type" => "checkAuthenticationPassword", "password" => text})
  end

  def send_message(chat_id, text) do
    send_wait(%{
      "@type" => "sendMessage",
      "chat_id" => chat_id,
      "input_message_content" => %{
        "@type" => "inputMessageText",
        "text" => %{"@type" => "formattedText", "text" => text}
      }
    })
  end

  def edit_message_text(chat_id, message_id, text) do
    send_wait(%{
      "@type" => "editMessageText",
      "chat_id" => chat_id,
      "message_id" => message_id,
      "input_message_content" => %{
        "@type" => "inputMessageText",
        "text" => %{"@type" => "formattedText", "text" => text}
      }
    })
  end
end
