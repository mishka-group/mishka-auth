defmodule MishkaAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :mishka_auth,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "MishkaAuth",
      source_url: "https://github.com/mishka-group/mishka-auth"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MishkaAuth.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.10", override: true},
      {:guardian, "~> 2.1", override: true},
      {:oauth2, "~> 2.0", override: true},
      {:ueberauth, "~> 0.6.3", override: true},
      {:ueberauth_google, "~> 0.9.0", override: true},
      {:ueberauth_github, "~> 0.8.0", override: true},
      {:jose, "~> 1.10", override: true},
      {:comeonin, "~> 5.3", override: true},
      {:bcrypt_elixir, "~> 2.2", override: true},
      {:ecto_enum, "~> 1.4", override: true},
      {:redix, "~> 0.11.1", override: true},
      {:postgrex, "~> 0.15.5", override: true},
      {:phoenix_ecto, "~> 4.1", override: true},
      {:phoenix, "~> 1.5", override: true},
      {:jason, "~> 1.2", override: true},
      {:cowboy, "~> 2.8", override: true},
      {:plug_cowboy, "~> 2.3", override: true},
      {:ex_doc, "~> 0.22.2", only: :dev, runtime: false},
      {:telemetry, "~> 0.4.2", override: true},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:poison, "~> 4.0", override: true}
    ]
  end

  defp description() do
    "A few sentences (a paragraph) describing the project."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "MishkaAuth",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* readme*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mishka-group/mishka-auth"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
