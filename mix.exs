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
      source_url: "https://github.com/mishka-group/mishka-auth",
      dialyzer: [plt_add_apps: [:mix]]
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
      {:oauth2, "~> 2.0"},
      {:ueberauth, "~> 0.6.3"},
      {:ueberauth_google, "~> 0.9.0"},
      {:ueberauth_github, "~> 0.8.0"},
      {:jose, "~> 1.10"},
      {:comeonin, "~> 5.3"},
      {:bcrypt_elixir, "~> 2.2"},
      {:poison, "~> 4.0"},
      {:ecto_enum, "~> 1.4"},
      {:redix, "~> 0.11.1"},
      {:telemetry, "~> 0.4.2"},
      {:ex_doc, "~> 0.22.2", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
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
