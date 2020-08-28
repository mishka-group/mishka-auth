defmodule MishkaAuth do

  alias MishkaAuth.Helper.HandleDirectRequest
  alias MishkaAuth.Helper.PhoenixConverter
  alias MishkaAuth.Client.Helper.HandleSocialRequest
  alias MishkaAuth.Client.Users.ClientToken


  @spec get_config_info(atom) :: any
  def get_config_info(parametr) do
    :mishka_auth
    |> Application.fetch_env!(MishkaAuth)
    |> Keyword.fetch!(parametr)
  end


  @spec callback_url(Plug.Conn.t()) :: binary
  def callback_url(conn) do
    Ueberauth.Strategy.Helpers.callback_url(conn)
  end

  @spec login_with_email(
          :current_token | :current_user | :refresh_token,
          Plug.Conn.t(),
          binary,
          binary
        ) :: Plug.Conn.t()
  def login_with_email(strategy, conn, email, password) do
    HandleDirectRequest.login_with_email(strategy, conn, email, password)
  end

  @spec login_with_username(
          :current_token | :current_user | :refresh_token,
          Plug.Conn.t(),
          binary,
          binary
        ) :: Plug.Conn.t()
  def login_with_username(strategy, conn, username, password) do
    HandleDirectRequest.login_with_username(strategy, conn, username, password)
  end

  @spec handle_callback(Plug.Conn.t(), any, atom | String.t(), binary, atom | String.t()) :: Plug.Conn.t()
  def handle_callback(conn, module_name, path, code, provider) do
    PhoenixConverter.callback_session(conn, module_name, path, code, provider)
  end

  @spec handle_social(
          Plug.Conn.t(),
          %{
            :__struct__ => Ueberauth.Auth | Ueberauth.Failure,
            :provider => atom | String.t(),
            :strategy => atom | String.t(),
            optional(:credentials) => any,
            optional(:errors) => any,
            optional(:extra) => any,
            optional(:info) => any,
            optional(:uid) => any
          },
          :auth | :fails,
          atom
        ) :: Plug.Conn.t()
  def handle_social(conn, auth, status, strategy) do
    HandleSocialRequest.back_request(auth, status, Ecto.UUID.generate(), strategy, conn)
  end

  @spec verify_token(binary, binary, :refresh_token) ::
          {:error, :verify_token, :access_token | :refresh_token}
          | {:ok, :verify_token, :refresh_token_and_access_token, binary}
  def verify_token(refresh_token, access_token, :refresh_token) do
    ClientToken.verify_token(refresh_token, access_token, :refresh_token)
  end

  @spec verify_token(binary, :access_token | :current_token | :refresh_token) ::
          {:error, :verify_token, :access_token | :current_token | :refresh_token}
          | {:ok, :verify_token, :access_token | :current_token | :refresh_token, binary}
  def verify_token(refresh_token, :refresh_token) do
    ClientToken.verify_token(refresh_token, :refresh_token)
  end

  def verify_token(access_token, :access_token) do
    ClientToken.verify_token(access_token, :access_token)
  end

  def verify_token(current_token, :current_token) do
    ClientToken.verify_token(current_token, :current_token)
  end


  @spec verify_and_update_token(Plug.Conn.t(), binary, any, :refresh_token) :: Plug.Conn.t()
  def verify_and_update_token(conn, refresh_token, access_token, :refresh_token) do
    ClientToken.verify_and_update_token(conn, refresh_token, access_token, :refresh_token)
  end

  @spec verify_and_update_token(Plug.Conn.t(), binary, :current_token | :refresh_token) ::
          Plug.Conn.t()
  def verify_and_update_token(conn, refresh_token, :refresh_token) do
    ClientToken.verify_and_update_token(conn, refresh_token, :refresh_token)
  end

  def verify_and_update_token(conn, current_token, :current_token) do
    ClientToken.verify_and_update_token(conn, current_token, :current_token)
  end

  @spec verify_and_update_current_token_with_getting_session(Plug.Conn.t(), :current_token) ::
          Plug.Conn.t()
  def verify_and_update_current_token_with_getting_session(conn, :current_token) do
    with {:ok, :get_session, :current_token, current_token} <- PhoenixConverter.get_session_with_key(conn, :current_token) do

      ClientToken.verify_and_update_token(conn, current_token, :current_token)

    else
      {:error, :get_session, :current_token} ->
        MishkaAuth.Helper.PhoenixConverter.drop_session(conn, :current_user)
        |> MishkaAuth.Helper.PhoenixConverter.session_redirect(get_config_info(:login_redirect), "Token expired. Please login.", :error)
    end
  end
end
