defmodule Uryi.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    %{"@type" => "ok"} =
      TD.execute(%{
        "@type" => "setLogVerbosityLevel",
        "@args" => %{"new_verbosity_level" => 1}
      })

    # td log file

    children = [
      {Finch, name: Uryi.finch(), pools: %{default: [protocol: :http2]}},
      {TD, handler: Uryi}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Uryi.Supervisor)
  end
end
