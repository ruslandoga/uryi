defmodule Uryi.PubSub do
  @moduledoc false

  def subscribe(topic) do
    Registry.register(Uryi.registry(), topic, [])
  end

  def broadcast(topic, message) do
    Registry.dispatch(Uryi.registry(), topic, fn entries ->
      for {pid, _} <- entries, do: send(pid, message)
    end)
  end
end
