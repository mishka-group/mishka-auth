defmodule MishkaAuth.Plug.LoginedCurrentTokenPlug do
  import Plug.Conn
  alias MishkaAuth.Helper.PhoenixConverter

  @spec init(any) :: any
  def init(default), do: default


  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, default) do
    PhoenixConverter.get_session_with_key(conn, :current_token)
    |> check_session(conn, default)
  end

  @spec check_session(
          {:error, :get_session, :current_token} | {:ok, :get_session, :current_token, any},
          Plug.Conn.t(),
          any
        ) :: Plug.Conn.t()
  def check_session({:ok, :get_session, :current_token, access_token}, conn, default) do
    case MishkaAuth.verify_token(access_token, :current_token) do
      {:ok, :verify_token, :current_token, user_id} ->
        conn
        |> assign(:client_logined, %{user_id: user_id})
      {:error, :verify_token, :current_token} ->
        check_session({:error, :get_session, :current_token}, conn, default)
    end

  end

  def check_session({:error, :get_session, :current_token}, conn, _default) do
    conn
    |> PhoenixConverter.drop_session(:current_token)
    |> PhoenixConverter.session_redirect("/", "You have no accses to see this page, Please try to login", :error)
    |> halt()
  end
end
