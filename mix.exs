defmodule Tablecopy.MixProject do
  use Mix.Project

  def project do
    [
      app: :tablecopy,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Tablecopy, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:postgrex, "~> 0.14"},
      {:temp, "~> 0.4"}
    ]
  end
end
