defmodule Bot.API do
  @moduledoc false

  def request(method, body, timeout \\ :timer.seconds(20)) do
    url = build_url(method)
    headers = [{"content-type", "application/json"}]
    body = Jason.encode_to_iodata!(body)
    req = Finch.build(:post, url, headers, body)
    Finch.request(req, Uryi.finch(), receive_timeout: timeout)
  end

  def build_url(method) do
    sep =
      case Uryi.tg_bot_env() do
        :test -> "/test/"
        _env -> "/"
      end

    IO.iodata_to_binary(["https://api.telegram.org/bot", Uryi.tg_bot_token(), sep, method])
  end
end
