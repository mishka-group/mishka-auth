defmodule MishkaAuth.Plug.RequestPlug do
  import Plug.Conn

  @strategies ["current_token", "current_user", "refresh_token"]

  @spec init(any) :: any

  def init(default), do: default

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()

  def call(conn, default) do
    conn
    |> put_session(:request_render, strategy(conn.params["strategy"]))
    |> configure_session(renew: true)
    |> assign(:handle_request, default)
  end

  defp strategy(strategy) when strategy in @strategies do
    strategy
  end

  defp strategy(_) do
    "current_user"
  end

end
