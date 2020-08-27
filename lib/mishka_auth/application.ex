defmodule MishkaAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      MishkaAuth.Repo,
      # Start the Telemetry supervisor
      MishkaAuthWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MishkaAuth.PubSub},
      # Start the Endpoint (http/https)
      MishkaAuthWeb.Endpoint,

      {Redix, name: :redix, password: "#{MishkaAuth.get_config_info(:redix)}"}
      # Start a worker by calling: MishkaAuth.Worker.start_link(arg)
      # {MishkaAuth.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MishkaAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MishkaAuthWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
