defmodule MishkaAuth.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Redix, name: :redix, password: "#{MishkaAuth.get_config_info(:redix)}"}
    ]
    opts = [strategy: :one_for_one, name: MishkaAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
