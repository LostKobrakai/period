defmodule Period.Mixfile do
  use Mix.Project

  def project do
    [
      app: :period,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      name: "Period",
      source_url: "https://github.com/LostKobrakai/period",
      homepage_url: "https://github.com/LostKobrakai/period",
      docs: [main: "Period", extras: ["README.md"]],
      package: package(),
      description: description()
    ]
  end

  defp description() do
    "Period is a library for working with time periods."
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Benjamin Milde"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/LostKobrakai/period"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:excoveralls, "~> 0.7", only: :test},
      {:stream_data, "~> 0.2", only: :test},
      {:ex_doc, "~> 0.18", only: :dev, runtime: false}
    ]
  end
end
