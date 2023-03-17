defmodule Uryi.TDNif do
  @moduledoc "TDLib client to let Uryi take over your Telegram account"
  @on_load :init

  def init do
    :erlang.load_nif('./priv/td_nif', 0)
  end

  def create, do: :erlang.nif_error(:not_loaded)
  def send(_, _), do: :erlang.nif_error(:not_loaded)
  def execute(_, _), do: :erlang.nif_error(:not_loaded)
  def recv(_, _), do: :erlang.nif_error(:not_loaded)
end
