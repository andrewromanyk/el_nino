defmodule ElNino.MixProject do
  use Mix.Project

  def project do
    [
      app: :el_nino,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElNino.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, github: "Kraigie/nostrum"},
      {:qex, "~> 0.5"},
      {:websockex, "~> 0.5.1"},
      {:req, "~> 0.6.2"}
    ]
  end
end
