defmodule Bot.Poller do
  @moduledoc false
  alias Bot.API
  require Logger

  def child_spec(opts) do
    %{id: __MODULE__, start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(_opts) do
    :proc_lib.spawn_link(__MODULE__, :loop, [0])
  end

  @doc false
  def loop(update_id) do
    params = %{"timeout" => 30, "offset" => update_id + 1}
    timeout = :timer.seconds(45)

    case API.request("getUpdates", params, timeout) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        %{"type" => "ok", "result" => result} = Jason.decode!(body)
        topic = Uryi.bot_topic()

        update_id =
          Enum.reduce(result, update_id, fn message, _update_id ->
            Uryi.PubSub.broadcast(topic, message)
            Map.fetch!(message, "update_id")
          end)

        __MODULE__.loop(update_id)

      {:error, reason} ->
        Logger.error(bot: reason)
        __MODULE__.loop(update_id)
    end
  end
end
