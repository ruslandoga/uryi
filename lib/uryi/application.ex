defmodule Uryi.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: Uryi.Finch, pools: %{default: [protocol: :http2]}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Uryi.Supervisor)
  end
end
