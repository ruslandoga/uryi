defmodule GPT do
  @moduledoc "OpenAI API client to generate Uryi responses"

  defmodule Error do
    defexception [:status, :message]
  end

  def response(message) do
    body = Jason.encode_to_iodata!(%{})
    headers = []
    url = ""

    request = Finch.build("POST", "", headers, body)

    case Finch.request(request, Uryi.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: status, body: body}} ->
        {:error, Error.exception(status: status, message: body)}

      {:error, _reason} = error ->
        error
    end
  end
end
