defmodule MishkaAuth do

  alias MishkaAuth.Helper.HandleDirectRequest
  alias MishkaAuth.Helper.PhoenixConverter
  alias MishkaAuth.Client.Helper.HandleSocialRequest
  alias MishkaAuth.Client.Users.ClientToken


  def get_config_info(parametr) do
    :mishka_auth
    |> Application.fetch_env!(MishkaAuth)
    |> Keyword.fetch!(parametr)
  end


  def callback_url(conn) do
    Ueberauth.Strategy.Helpers.callback_url(conn)
  end

  def login_with_email(strategy, conn, email, password) do
    HandleDirectRequest.login_with_email(strategy, conn, email, password)
  end

  def login_with_username(strategy, conn, username, password) do
    HandleDirectRequest.login_with_username(strategy, conn, username, password)
  end

  def handle_callback(conn, module_name, path, code, provider) do
    PhoenixConverter.callback_session(conn, module_name, path, code, provider)
  end

  def handle_social(conn, auth, status, strategy) do
    HandleSocialRequest.back_request(auth, status, Ecto.UUID.generate(), strategy, conn)
  end

  def verify_token(refresh_token, access_token, :refresh_token) do
    ClientToken.verify_token(refresh_token, access_token, :refresh_token)
  end

  def verify_token(refresh_token, :refresh_token) do
    ClientToken.verify_token(refresh_token, :refresh_token)
  end

  def verify_token(access_token, :access_token) do
    ClientToken.verify_token(access_token, :access_token)
  end

  def verify_token(current_token, :current_token) do
    ClientToken.verify_token(current_token, :current_token)
  end

  def verify_and_update_token(conn, refresh_token, access_token, :refresh_token) do
    ClientToken.verify_and_update_token(conn, refresh_token, access_token, :refresh_token)
  end

  def verify_and_update_token(conn, refresh_token, :refresh_token) do
    ClientToken.verify_and_update_token(conn, refresh_token, :refresh_token)
  end

  def verify_and_update_token(conn, current_token, :current_token) do
    ClientToken.verify_and_update_token(conn, current_token, :current_token)
  end

  def validate_token(conn, refresh_token, access_token, :refresh_token) do
    ClientToken.verify_and_update_token(conn, refresh_token, access_token, :refresh_token)
  end

  def validate_token(conn, :current_token) do
    with {:ok, :get_session, :current_token, current_token} <- PhoenixConverter.get_session_with_key(conn, :current_token) do

      ClientToken.verify_and_update_token(conn, current_token, :current_token)

    else
      {:error, :get_session, :current_token} ->
        MishkaAuth.Helper.PhoenixConverter.drop_session(conn, :current_user)
        |> MishkaAuth.Helper.PhoenixConverter.session_redirect(get_config_info(:login_redirect), "Token expired. Please login.", :error)
    end
  end
end
