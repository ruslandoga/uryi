defmodule Uryi.MixProject do
  use Mix.Project

  def project do
    [
      app: :uryi,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:elixir_make | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Uryi.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:finch, "~> 0.15.0"},
      {:jason, "~> 1.4"},
      {:castore, "~> 1.0", override: true},
      {:elixir_make, "~> 0.7.5", runtime: false}
    ]
  end
end
