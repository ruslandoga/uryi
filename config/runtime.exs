import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# tdlib
td_api_id = String.to_integer(System.fetch_env!("TD_API_ID"))
td_api_hash = System.fetch_env!("TD_API_HASH")
td_use_test_dc = !!System.get_env("TD_USE_TEST_DC") || config_env() == :test
default_td_database_directory = Path.join(System.tmp_dir(), "uryi_#{config_env()}")
td_database_directory = System.get_env("TD_DATABASE_DIRECTORY") || default_td_database_directory

# openapi
openai_api_key = System.fetch_env!("OPENAI_API_KEY")

# gpt
gpt_model = System.get_env("GPT_MODEL", "gpt-3.5-turbo")
default_gpt_prompt = "You are an AI secretary named Uryi. Answer the following message:"
gpt_prompt = System.get_env("GPT_PROMPT", default_gpt_prompt)

# uryi
enabled_in =
  System.fetch_env!("ENABLED_IN")
  |> String.split(",", trim: true)
  |> Enum.map(&String.trim/1)
  |> Enum.reject(&(&1 == ""))
  |> Enum.map(fn
    "@" <> _ = username -> username
    chat_id -> String.to_integer(chat_id)
  end)

config :uryi,
  td_api_id: td_api_id,
  td_api_hash: td_api_hash,
  td_use_test_dc: td_use_test_dc,
  td_database_directory: td_database_directory,
  openai_api_key: openai_api_key,
  gpt_model: gpt_model,
  gpt_prompt: gpt_prompt,
  enabled_in: enabled_in
