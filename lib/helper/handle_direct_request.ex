defmodule MishkaAuth.Helper.HandleDirectRequest do

  alias MishkaAuth.Client.Users.ClientUserQuery
  alias MishkaAuth.Helper.PhoenixConverter
  alias MishkaAuth.Client.Identity.ClientIdentityQuery

  @type username() :: String.t()
  @type email() :: String.t()
  @type password() :: String.t()
  @type temporary_id() :: Ecto.UUID.t

  @login_incorrect_redirect "/"
  @successful_register_redirect "/"

  @doc """
    you can get username and password of user and create refresh_token for mobile app and token or current_user for storing session .
    this is Owner Password Credentials Grant json mobile application strategy and html render.
    it should be noted, grant_type and scope will be added for handling your user request and requested data.
    ```
      {
        :refresh_token,
        :current_token,
        :current_user
      }
    ```
  """
  @spec login_with_username(atom(), Plug.Conn.t(), username(), password()) :: Plug.Conn.t()

  def login_with_username(:refresh_token, conn, username, password) do
    with {:ok, :check_password_with_username, :username, user_info} <- ClientUserQuery.check_password_user_and_password(username, password, :username) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :refresh_token, 2)
    else
      _ ->
        PhoenixConverter.render_json(conn, %{error: "username or password is incorrect."}, :error, 401)
    end
  end


  def login_with_username(:current_token, conn, username, password) do
    with {:ok, :check_password_with_username, :username, user_info} <- ClientUserQuery.check_password_user_and_password(username, password, :username) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :current_token, 2)
    else
      _ ->
        PhoenixConverter.session_redirect(conn, @login_incorrect_redirect, "username or password is incorrect.", :error)
    end
  end


  def login_with_username(:current_user, conn, username, password) do
    with {:ok, :check_password_with_username, :username, user_info} <- ClientUserQuery.check_password_user_and_password(username, password, :username) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :current_user, 2)
    else
      _ ->
        PhoenixConverter.session_redirect(conn, @login_incorrect_redirect, "username or password is incorrect.", :error)
    end
  end



  @doc """
    you can get email and password of user and create refresh_token for mobile app. this is
    Owner Password Credentials Grant json mobile application strategy
    it should be noted, grant_type and scope will be added for handling your user request and requested data.
  """
  @spec login_with_email(atom(), Plug.Conn.t(), email(), password()) :: Plug.Conn.t()

  def login_with_email(:refresh_token, conn, email, password) do
    with {:ok, :check_password_with_username, :email, user_info} <- ClientUserQuery.check_password_user_and_password(email, password, :email) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :refresh_token, 2)
    else
      _ ->
        PhoenixConverter.render_json(conn, %{error: "email or password is incorrect"}, :error, 401)
    end
  end


  def login_with_email(:current_token, conn, email, password) do
    with {:ok, :check_password_with_username, :email, user_info} <- ClientUserQuery.check_password_user_and_password(email, password, :email) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :current_token, 2)
    else
      _ ->
        PhoenixConverter.session_redirect(conn, @login_incorrect_redirect, "email or password is incorrect.", :error)
    end
  end


  def login_with_email(:current_user, conn, email, password) do
    with {:ok, :check_password_with_username, :email, user_info} <- ClientUserQuery.check_password_user_and_password(email, password, :email) do
      MishkaAuth.Strategy.registered_user_routing(user_info.id, conn, :current_user, 2)
    else
      _ ->
        PhoenixConverter.session_redirect(conn, @login_incorrect_redirect, "email or password is incorrect.", :error)
    end
  end


  @spec register(Plug.Conn.t(), map, temporary_id(), :social, :html | :json) :: Plug.Conn.t()

  def register(conn, params, temporary_id, :social, type) do
    case ClientUserQuery.add_user(ClientUserQuery.set_set_systematic_user_data(params, :social)) do
      {:ok, :add_user, user_info} ->

        ClientIdentityQuery.add_with_user_redis_data(temporary_id, user_info.id)

        successful_register_type(type, conn, "Your registration was successful!, you can login with your social network profile.")

      {:error, :add_user, changeset} ->
        unsuccessful_register_type(type, conn, changeset)
    end
  end


  @spec register(Plug.Conn.t(), map, :normal, :html | :json) :: Plug.Conn.t()

  def register(conn, params, :normal, type) do
    case ClientUserQuery.add_user(ClientUserQuery.set_set_systematic_user_data(params, :direct)) do
      {:ok, :add_user, _user_info} ->
        successful_register_type(type, conn, "Your registration was successful!, please check your email to active your account.")

      {:error, :add_user, changeset} ->
        unsuccessful_register_type(type, conn, changeset)

    end
  end

  defp successful_register_type(type, conn, msg) do
    case type do
      :json ->
        PhoenixConverter.render_json(conn, %{message: msg}, :ok, 200)
      :html ->
        PhoenixConverter.session_redirect(conn, @successful_register_redirect, msg, :info)
    end
  end


  defp unsuccessful_register_type(type, conn, changeset) do
    case type do
      :json ->
        PhoenixConverter.render_json(conn, %{error_messages: MishkaAuth.Extra.get_changeset_error(changeset)}, :ok, 400)
      :html ->
        PhoenixConverter.changeset_redirect(conn, changeset)
    end
  end

end
