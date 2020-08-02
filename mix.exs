defmodule MishkaAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :mishka_auth,
      version: "0.0.1",
      elixir: "~> 1.10",
      config_path: "./config/config.exs",
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
      {:plug, "~> 1.10"},
      {:guardian, "~> 2.1"},
      {:oauth2, "~> 2.0", override: true},
      {:ueberauth, "~> 0.6.3"},
      {:ueberauth_google, "~> 0.9.0"},
      {:ueberauth_github, "~> 0.8.0"},
      {:jose, "~> 1.10"},
      {:comeonin, "~> 5.3"},
      {:bcrypt_elixir, "~> 2.2"},
      {:ecto_enum, "~> 1.4"},
      {:redix, "~> 0.11.1"},
      {:postgrex, "~> 0.15.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix, "~> 1.5"},
      {:jason, "~> 1.2"},
      {:cowboy, "~> 2.8"},
      {:plug_cowboy, "~> 2.3"},
      {:ex_doc, "~> 0.22.2", only: :dev, runtime: false},
      {:telemetry, "~> 0.4.2", override: true},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:poison, "~> 4.0"}
    ]
  end

  defp description() do
    "A few sentences (a paragraph) describing the project."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "postgrex",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* readme*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mishka-group/mishka-auth"}
    ]
  end
end
