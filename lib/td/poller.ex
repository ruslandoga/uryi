defmodule TD.Poller do
  @moduledoc false
  alias TD.Nif

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(_opts) do
    client_id = Nif.create_client_id()

    :ok =
      TD.send(client_id, %{
        "@type" => "getOption",
        "name" => "version",
        "@extra" => "VERSION"
      })

    :proc_lib.spawn_link(__MODULE__, :loop, [])
  end

  @doc false
  def loop do
    case Nif.recv(1.0) do
      message when is_binary(message) ->
        Uryi.PubSub.broadcast(Uryi.td_topic(), Jason.decode!(message))
        __MODULE__.loop()

      nil ->
        __MODULE__.loop()
    end
  end
end
