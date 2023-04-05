defmodule TD.Nif do
  @moduledoc false
  @on_load :load_nif
  @compile {:autoload, false}

  def load_nif do
    path = :filename.join(:code.priv_dir(:uryi), 'td_nif')
    :erlang.load_nif(path, 0)
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
