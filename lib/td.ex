defmodule TD do
  @moduledoc "TDLib client to allow Uryi overtake an account"
  import Kernel, except: [send: 2]
  alias TD.Nif

  @spec send(integer, map) :: :ok
  def send(client_id, request) when is_map(request) do
    Nif.send(client_id, Jason.encode_to_iodata!(request))
  end

  @spec execute(map) :: map
  def execute(request) when is_map(request) do
    request |> Jason.encode_to_iodata!() |> Nif.execute() |> Jason.decode!()
  end
end
