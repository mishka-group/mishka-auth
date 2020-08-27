defmodule MishkaAuth.Strategy do
  alias MishkaAuth.Client.Users.ClientToken
  alias MishkaAuth.Helper.PhoenixConverter



  @type user_id() :: Ecto.UUID.t
  @type redirect_url() :: String.t()
  @type strategy_type() :: atom()
  @type conn() :: Plug.Conn.t()
  @type auth_version() :: float() | integer()
  @type error_msg() :: String.t()
  @type token() :: String.t()

  # Strategies were created
  # :current_user // *.html render
  # :current_token // *.html render
  # :refresh_token // *.json render




  # inSite normal current user
  @spec registered_user_routing(user_id(), Plug.Conn.t(), :current_user | :current_token | :refresh_token, auth_version()) ::
          Plug.Conn.t()
  def registered_user_routing(user_id, conn, :current_user, 2) do
    PhoenixConverter.store_session(:current_user, user_id, MishkaAuth.get_config_info(:user_redirect_path), conn, MishkaAuth.get_config_info(:authenticated_msg))
  end



  # inSite normal current user with jtw token
  def registered_user_routing(user_id, conn, :current_token, 2) do
    {:ok, _def_name, token} = ClientToken.create_and_update_current_token(user_id)
    PhoenixConverter.store_session(:current_token, token, MishkaAuth.get_config_info(:user_redirect_path), conn, MishkaAuth.get_config_info(:authenticated_msg))
  end



  # inApi Refresh Token mobile app type, and has backend (external site)
  def registered_user_routing(user_id, conn, :refresh_token, 2) do
    # create or update refresh token
    # save refresh token into redis for some days Like: {10 days}
    # create access token
    with {:ok, :save_token_into_redis, :create, user_refresh_token} <- ClientToken.create_and_save_refresh_token(user_id, %{}),
        {:ok, access_token, clime} <- ClientToken.create_access_token(user_id) do
        PhoenixConverter.render_json(conn, %{
          refresh_token: user_refresh_token,
          access_token: access_token,
          expires_in: clime["exp"],
          token_type: clime["typ"]
        }, :ok, 200)
    else
      _ -> PhoenixConverter.render_json(conn, %{error: "Server Error"}, :error, 500)
    end
  end

  # PKCE Refresh Token mobile app type (external site)



  @spec none_registered_user_routing(Plug.Conn.t(), map(), user_id(), any(), :refresh_token | :current_user | :current_token) :: Plug.Conn.t()
  def none_registered_user_routing(conn, user_temporary_data, temporary_user_uniq_id, status, :refresh_token) do
    PhoenixConverter.render_json(conn, %{
      user_info: Map.drop(user_temporary_data, ["token", "uid", "provider"]),
      temporary_id: temporary_user_uniq_id
    }, :ok, status)
  end


  def none_registered_user_routing(conn, user_temporary_data, temporary_user_uniq_id, _status, :current_user) do
    if MishkaAuth.get_config_info(:automatic_registration) do
      # register user
      # add identities
    else
      PhoenixConverter.register_data(conn, user_temporary_data, temporary_user_uniq_id)
    end
  end


  def none_registered_user_routing(conn, user_temporary_data, temporary_user_uniq_id, _status, :current_token) do
    if MishkaAuth.get_config_info(:automatic_registration) do
      # register user
      # add identities
    else
      PhoenixConverter.register_data(conn, user_temporary_data, temporary_user_uniq_id)
    end
  end


  @spec failed_none_registered_user_routing(Plug.Conn.t(), map(), integer(), :refresh_token | :current_user | :current_token) :: Plug.Conn.t()
  def failed_none_registered_user_routing(conn, attrs, status, :refresh_token) do
    PhoenixConverter.render_json(conn, attrs, :error, status)
  end

  def failed_none_registered_user_routing(conn, attrs, _status, :current_user) do
    PhoenixConverter.session_redirect(conn, "/", attrs.error, :error)
  end

  def failed_none_registered_user_routing(conn, attrs, _status, :current_token) do
    PhoenixConverter.session_redirect(conn, "/", attrs.error, :error)
  end



  def auth_error_strategy(conn, strategy_type, errors, status) do
    case strategy_type do
      :refresh_token ->
        PhoenixConverter.render_json(conn, errors, :error, status)
      _ ->
        error = List.first(errors)
        PhoenixConverter.session_redirect(conn, "/", error.message, :error)
    end
  end
end
