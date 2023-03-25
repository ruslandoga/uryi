defmodule TD.Poller do
  @moduledoc "Polls for new events from TDLib"
  alias TD.Nif
  require Logger

  @callback handle_event(map) :: any

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    handler = Keyword.fetch!(opts, :handler)
    {:ok, :proc_lib.spawn_link(__MODULE__, :recv, [handler])}
  end

  @doc false
  def recv(handler) do
    case Nif.recv(1.0) do
      event when is_binary(event) ->
        event = Jason.decode!(event)
        handler.handle_event(event)

      nil ->
        :ok
    end

    __MODULE__.recv(handler)
  end
end
