defmodule Uryi do
  @moduledoc "ChatGPT over Telegram secretary"
  @app :uryi

  @doc false
  def finch, do: __MODULE__.Finch
  def registry, do: __MODULE__.Registry
  def bot_topic, do: "bot"
  def td_topic, do: "td"
  def fetch_env!(key), do: Application.fetch_env!(@app, key)
  def put_env(key, value), do: Application.put_env(@app, key, value)

  env_keys = [
    :owner_id,
    :enabled_in,
    :td_version,
    :td_commit,
    :td_database_directory,
    :td_api_id,
    :td_api_hash,
    :td_use_test_dc,
    :tg_bot_token,
    :tg_bot_env
  ]

  for key <- env_keys do
    def unquote(key)(), do: Application.fetch_env!(@app, unquote(key))
  end
end
