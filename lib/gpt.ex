defmodule GPT do
  @moduledoc "OpenAI API client to generate Uryi responses"

  def build(path, api_key) do
    url = Path.join("https://api.openai.com", path)

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{api_key}"}
    ]

    Finch.build("GET", url, headers)
  end

  def build(path, api_key, params) when is_map(params) do
    url = Path.join("https://api.openai.com", path)

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{api_key}"}
    ]

    body = Jason.encode_to_iodata!(params)
    Finch.build("POST", url, headers, body)
  end

  def build_chat_completion(text, opts \\ []) do
    api_key = Keyword.fetch!(opts, :api_key)
    model = Keyword.get(opts, :model, "gpt-3.5-turbo")
    prompt = Keyword.fetch!(opts, :prompt)
    temperature = Keyword.get(opts, :temperature, 0.7)
    max_tokens = Keyword.get(opts, :max_tokens, 42)
    stream = Keyword.get(opts, :stream, true)

    params = %{
      "model" => model,
      "messages" => [
        %{
          "role" => "system",
          "content" => prompt <> " " <> text
        }
      ],
      "temperature" => temperature,
      "max_tokens" => max_tokens,
      "stream" => stream
    }

    build("/v1/chat/completions", api_key, params)
  end

  def request(req, opts \\ []) do
    Finch.request(req, Uryi.finch(), opts)
  end

  def stream(req, f) do
    stream = fn
      {:status, 200}, _ ->
        :cont

      {:status, _status} = status, _ ->
        {:error, status}

      {:headers, _headers}, :cont = cont ->
        cont

      {:data, data}, :cont = cont ->
        f.(data)
        cont

      _, error ->
        error
    end

    result = Finch.stream(req, Uryi.finch(), _acc = nil, stream, receive_timeout: :infinity)

    case result do
      {:ok, _} -> :ok
      {:error, _reason} = error -> error
    end
  end
end
