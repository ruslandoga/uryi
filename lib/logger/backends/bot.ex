defmodule Logger.Backends.Bot do
  @moduledoc "Logger backend as a Telegram bot"
  @behaviour :gen_event

  defstruct buffer: [],
            buffer_size: 0,
            colors: nil,
            device: nil,
            format: nil,
            level: nil,
            max_buffer: nil,
            metadata: nil,
            output: nil,
            ref: nil

  @impl true
  def init(_eh) do
    {:ok, nil}
  end
end
