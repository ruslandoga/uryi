defmodule TD.Nif do
  @moduledoc false
  @on_load :init

  def init do
    :erlang.load_nif('./priv/td_nif', 0)
  end

  @spec create_client_id :: integer
  def create_client_id, do: :erlang.nif_error(:not_loaded)

  @spec send(integer, iodata) :: :ok
  def send(_client_id, _json), do: :erlang.nif_error(:not_loaded)

  @spec execute(iodata) :: binary
  def execute(_json), do: :erlang.nif_error(:not_loaded)

  @spec recv(float) :: binary | nil
  def recv(_timeout), do: :erlang.nif_error(:not_loaded)
end
