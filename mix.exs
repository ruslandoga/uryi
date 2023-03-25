defmodule Uryi.MixProject do
  use Mix.Project

  def project do
    [
      app: :uryi,
      version: "0.1.0",
      elixir: "~> 1.14",
      compilers: [:elixir_make | Mix.compilers()],
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Uryi.Application, []}
    ]
  end

  defp deps do
    [
      {:finch, "~> 0.15.0"},
      {:jason, "~> 1.4"},
      {:castore, "~> 1.0", override: true},
      {:elixir_make, "~> 0.7.5", runtime: false}
    ]
  end

  defp releases do
    [uryi: [include_executables_for: [:unix]]]
  end
end
