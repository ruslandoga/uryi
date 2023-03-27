defmodule GPT do
  @moduledoc "OpenAI API client to generate Uryi responses"

  def build(path) do
    url = Path.join("https://api.openai.com", path)

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{Uryi.openai_api_key()}"}
    ]

    Finch.build("GET", url, headers)
  end

  def build(path, params) when is_map(params) do
    url = Path.join("https://api.openai.com", path)

    headers = [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{Uryi.openai_api_key()}"}
    ]

    body = Jason.encode_to_iodata!(params)
    Finch.build("POST", url, headers, body)
  end

  def chat_completion(text) do
    params = %{
      "model" => Uryi.gpt_model(),
      "messages" => [
        %{
          "role" => "system",
          "content" => Uryi.gpt_prompt() <> " " <> text
        }
      ],
      "temperature" => 0.7,
      "max_tokens" => 100
    }

    req = build("/v1/chat/completions", params)
    opts = [receive_timeout: :timer.minutes(2)]

    with {:ok, %Finch.Response{status: 200, body: body}} <- Finch.request(req, Uryi.finch(), opts) do
      %{"choices" => [%{"message" => %{"content" => content}}]} = Jason.decode!(body)
      {:ok, content}
    end
  end

  def stream_chat_completion(text, f) when is_function(f, 2) do
    params = %{
      "model" => Uryi.gpt_model(),
      "messages" => [
        %{
          "role" => "system",
          "content" => Uryi.gpt_prompt() <> " " <> text
        }
      ],
      "temperature" => 0.7,
      "max_tokens" => 100,
      "stream" => true
    }

    req = build("/v1/chat/completions", params)

    stream = fn
      {:status, status}, nil ->
        {status, [], [], {"", nil}}

      {:headers, headers}, acc ->
        put_elem(acc, 1, elem(acc, 1) ++ headers)

      {:data, data}, {200, _headers, _body, {text, f_acc} = stream_acc} = acc ->
        stream_acc =
          data
          |> String.split("\n\n")
          |> Enum.reduce(stream_acc, fn data, stream_acc ->
            case data do
              "data: [DONE]" <> _ ->
                stream_acc

              "data: " <> json ->
                json = Jason.decode!(json)
                tokens = get_in(json, ["choices", Access.all(), "delta", "content"])
                tokens = tokens |> Enum.reject(&is_nil/1) |> IO.iodata_to_binary()
                text = text <> tokens
                f_acc = if text == "", do: f_acc, else: f.(text, f_acc)
                {text, f_acc}

              "" ->
                stream_acc
            end
          end)

        put_elem(acc, 3, stream_acc)

      {:data, body}, acc ->
        put_elem(acc, 2, [elem(acc, 2) | body])
    end

    opts = [receive_timeout: :timer.minutes(2)]
    result = Finch.stream(req, Uryi.finch(), _acc = nil, stream, opts)

    with {:ok, {status, headers, body, _stream_acc}} <- result do
      {:ok, %Finch.Response{status: status, headers: headers, body: IO.iodata_to_binary(body)}}
    end
  end
end
