defmodule MishkaAuth.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Redix, name: :redix, password: "#{MishkaAuth.get_config_info(:redix)}"}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MishkaAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
