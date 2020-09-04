defmodule MishkaAuth.Plug.LoginedCurrentUserPlug do
  import Plug.Conn
  alias MishkaAuth.Helper.PhoenixConverter

  def init(default), do: default


  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, default) do
    PhoenixConverter.get_session_with_key(conn, :current_user)
    |> check_session(conn, default)
  end

  @spec check_session(
          {:error, :get_session, :current_user} | {:ok, :get_session, :current_user, any},
          Plug.Conn.t(),
          any
        ) :: Plug.Conn.t()
  def check_session({:ok, :get_session, :current_user, user_id}, conn, _default) do
    conn
    |> assign(:client_logined, %{user_id: user_id})
  end

  def check_session({:error, :get_session, :current_user}, conn, _default) do
    conn
    |> PhoenixConverter.drop_session(:current_user)
    |> PhoenixConverter.session_redirect("/", "You have no accses to see this page, Please try to login", :error)
    |> halt()
  end
end
