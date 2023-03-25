defmodule Bot.Poller do
  @moduledoc "Polls for new messages from Telegram"
  alias Bot.API
  require Logger

  @callback handle_message(map) :: any

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    handler = Keyword.fetch!(opts, :handler)
    state = %{handler: handler, update_id: 0}
    {:ok, :proc_lib.spawn_link(__MODULE__, :loop, [state])}
  end

  @doc false
  def loop(state) do
    %{handler: handler, update_id: update_id} = state
    params = %{"timeout" => 30, "offset" => update_id + 1}
    timeout = :timer.seconds(45)

    state =
      case API.request("getUpdates", params, timeout) do
        {:ok, %Finch.Response{status: 200, body: body}} ->
          %{"ok" => true, "result" => result} = Jason.decode!(body)

          update_id =
            Enum.reduce(result, update_id, fn message, _update_id ->
              handler.handle_message(message)
              Map.fetch!(message, "update_id")
            end)

          %{state | update_id: update_id}

        {:ok, %Finch.Response{} = resp} ->
          Logger.error(bot: resp)
          state

        {:error, reason} ->
          Logger.error(bot: reason)
          :timer.sleep(:timer.seconds(5))
          state
      end

    __MODULE__.loop(state)
  end
end
