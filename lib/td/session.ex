defmodule TD.Session do
  @moduledoc false
  use GenServer
  alias TD.Nif
  @behaviour TD.Poller

  @callback td_new_message(map) :: any
  @callback td_auth(map) :: any

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def client_id do
    GenServer.call(__MODULE__, :client_id)
  end

  def handler do
    GenServer.call(__MODULE__, :handler)
  end

  def await(extra, timeout \\ :timer.seconds(5)) do
    GenServer.call(__MODULE__, {:await, extra}, timeout)
  end

  @impl true
  def handle_event(%{"@type" => "updateNewMessage"} = event) do
    Task.start(fn -> handler().td_new_message(event) end)
  end

  def handle_event(%{"@extra" => extra} = event) do
    GenServer.cast(__MODULE__, {:extra, extra, event})
  end

  def handle_event(%{"@type" => "updateAuthorizationState"} = event) do
    %{"authorization_state" => %{"@type" => type}} = event

    case type do
      "authorizationStateWaitTdlibParameters" ->
        %{"@client_id" => client_id} = event
        TD.set_tdlib_parameters(client_id)

      type
      when type in [
             "authorizationStateWaitPhoneNumber",
             "authorizationStateWaitCode",
             "authorizationStateWaitPassword"
           ] ->
        # TODO crash here -> new client id -> db lock error
        handler().td_auth(event)

      "authorizationStateReady" ->
        :ok
    end
  end

  def handle_event(_event), do: :ignore

  @impl true
  def init(opts) do
    handler = Keyword.fetch!(opts, :handler)
    client_id = Nif.create_client_id()
    :ok = TD.send(client_id, %{"@type" => "getOption", "name" => "version"})
    state = %{handler: handler, client_id: client_id, await: %{}}
    {:ok, state}
  end

  @impl true
  def handle_call(:client_id, _from, state) do
    {:reply, state.client_id, state}
  end

  def handle_call(:handler, _from, state) do
    {:reply, state.handler, state}
  end

  def handle_call({:await, extra}, from, state) do
    state = Map.update!(state, :await, fn await -> Map.put(await, extra, from) end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:extra, extra, event}, state) do
    %{await: await} = state
    {from, await} = Map.pop(await, extra)
    if from, do: GenServer.reply(from, event)
    {:noreply, %{state | await: await}}
  end
end
