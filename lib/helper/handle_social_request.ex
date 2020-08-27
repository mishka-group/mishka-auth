defmodule MishkaAuth.Client.Helper.HandleSocialRequest do
  alias MishkaAuth.Client.{Users.ClientUserQuery, Identity.ClientIdentityQuery}

  @temporary_table "temporary_user_data"
  @ttl_time_of_temporary_social_data 18000 #5 hour
  @auth_version 2


  @type temporary_user_uniq_id() :: String.t()
  @type token() :: String.t()
  @type provider() :: atom() | String.t()
  @type social_uid() :: String.t() | integer()
  @type strategy_type() :: atom()
  @type conn() :: Plug.Conn.t()





  # `AuthController` test example: https://github.com/ueberauth/ueberauth_example/issues/22

  @doc """
    main function which helps us to call back router and handle social request. is there a user we want ro create. register or sign in
  """

  @spec back_request(%Ueberauth.Auth{} | %Ueberauth.Failure{}, atom(), temporary_user_uniq_id(), strategy_type(), Plug.Conn.t()) ::
  {:ok, :config_user_social_data, :exist_user, token(), token()}
  | {:ok, :config_user_social_data, :none_user, temporary_user_uniq_id()}
  | {:error, :get_basic_data, any()}
  | {:error, :config_user_social_data, :exist_user | :none_user}
  | Plug.Conn.t()

  def back_request(auth, :auth, temporary_user_uniq_id, strategy_type, conn) do
    IO.inspect auth.info.urls
    auth.info
    |> get_basic_data(auth.provider, auth.uid)
    |> does_user_email_exist?()
    |> create_or_update_user(auth.provider, auth.credentials.token, temporary_user_uniq_id)
    |> config_user_social_data(strategy_type, conn)
  end

  def back_request(auth, :fails, _temporary_user_uniq_id, strategy_type, conn) do
    if auth.errors != [] do
      MishkaAuth.Strategy.auth_error_strategy(conn, strategy_type, error_getter(auth.errors), 401)
    else
      MishkaAuth.Strategy.auth_error_strategy(conn, strategy_type, [%{message: "unexpected error. try again.", message_key: "unexpected_error"}], 401)
    end
  end

  @doc """
    get basic data after sending provider output to callback router
  """
  @spec get_basic_data(%Ueberauth.Auth.Info{}, atom(), integer() | float() | String.t()) :: {:ok, :get_basic_data, map(), String.t()}

  def get_basic_data(user_info, provider, uid) when provider == :github do
    {:ok, :get_basic_data,
      %{
        email:  "#{user_info.email}",
        name:  "#{user_info.name}",
        lastname:  "#{user_info.last_name}",
        nickname:  "#{user_info.nickname}",
        avatar_url:  "#{user_info.urls.avatar_url}",
        username:  "#{MishkaAuth.Extra.get_github_username(user_info.urls.api_url)}",
        provider: :github
      },
      "#{uid}"
    }
  end

  def get_basic_data(user_info, provider, uid) when provider == :google do
    IO.inspect user_info
    {:ok, :get_basic_data,
      %{
        email:  "#{user_info.email}",
        name:  "#{user_info.first_name}",
        lastname:  "#{user_info.last_name}",
        nickname:  "#{user_info.nickname}",
        avatar_url:  "#{user_info.image}",
        username:  "#{user_info.first_name}",
        provider: :google
      },
      "#{uid}"
    }
  end

  @doc """
    if there are errors after returning social provider, this function create a list of errors
  """
  @spec error_getter(any) :: [any]
  def error_getter(errors) do
    Enum.map(errors, fn err ->
      %{message: err.message, message_key: err.message_key}
    end)
  end

  @doc """
    this function checks your databse if user email exist or not
  """
  @spec does_user_email_exist?({:ok, :get_basic_data, map(), String.t()}) ::
            {:does_user_email_exist?, {:error, :find_user_with_email}, map(), String.t()}
          | {:does_user_email_exist?, {:ok, :find_user_with_email, Ecto.Schema.t()} , map(), String.t()}
          | {:error, :get_basic_data, any}

  def does_user_email_exist?({:ok, :get_basic_data, user_info, uid}) do
    {:does_user_email_exist?, ClientUserQuery.find_user_with_email(user_info.email), user_info, uid}
  end


  @doc """
    if user email exist or not this function helps to update Identity or save data on temporary redis table
  """
  @spec create_or_update_user(
    {:does_user_email_exist?, {:error, :find_user_with_email}, map(), String.t()}
    | {:does_user_email_exist?, {:ok, :find_user_with_email, Ecto.Schema.t()} , map(), String.t()},
    atom(), token(), temporary_user_uniq_id()
  ) ::
  {:ok, :create_or_update_user, :save_temporary_social_data, temporary_user_uniq_id()}
  | {:ok, :add_identity | :edit_identity, Ecto.Schema.t()}


  def create_or_update_user({:does_user_email_exist?, {:error, :find_user_with_email}, user_info, uid}, provider, token, temporary_user_uniq_id) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(
      @temporary_table,
      temporary_user_uniq_id,
      %{
        email:  "#{user_info.email}",
        name:  "#{user_info.name}",
        lastname:  "#{user_info.lastname}",
        nickname: "#{user_info.nickname}",
        avatar_url:  "#{user_info.avatar_url}",
        username:  "#{user_info.username}",
        provider: "#{provider}",
        token: "#{token}",
        uid: "#{uid}"
      },
      "#{@ttl_time_of_temporary_social_data}"
    )
    {:ok, :create_or_update_user, :save_temporary_social_data, temporary_user_uniq_id}
  end

  def create_or_update_user({:does_user_email_exist?, {:ok, :find_user_with_email, exist_user} , _user_info, uid}, provider, token, _temporary_user_uniq_id) do
    case ClientIdentityQuery.find_user_identity(exist_user.id, provider) do
      {:error, :find_user_identity, provider} ->
        add_user_identity(exist_user, provider, uid, token)

      {:ok, :find_user_identity, identity} ->
        update_user_identity(exist_user, uid, identity, token)
    end
  end


  @doc """
    creates an Identity data map and saves after finding user but there is not an Identity for this provider concerned
  """
  @spec add_user_identity(Ecto.Schema.t(), provider(), social_uid(), token()) ::
  {:ok, :add_identity , Ecto.Schema.t()} | {:error, :add_identity, Ecto.Changeset.t()}

  def add_user_identity(exist_user, provider, uid, token) do
    ClientIdentityQuery.add_identity(%{
      user_id: exist_user.id,
      identity_provider: provider,
      uid: "#{uid}",
      token: "#{token}"
    })
  end


  @doc """
    update an Identity data map and edit after finding user, there is  an Identity for this provider concerned
  """
  @spec update_user_identity(Ecto.Schema.t(), social_uid(), Ecto.Schema.t(), token()) ::{:ok, :edit_identity , Ecto.Schema.t()}

  def update_user_identity(exist_user, uid, identity, token) do
    ClientIdentityQuery.edit_identity(identity.id,%{
      user_id: exist_user.id,
      identity_provider: identity.identity_provider,
      uid: "#{uid}",
      token: "#{token}"
    })
  end


  @spec config_user_social_data(
    {:ok, :edit_identity, Ecto.Schema.t()}
    | {:ok, :add_identity, Ecto.Schema.t()}
    | {:ok, :create_or_update_user, :save_temporary_social_data, temporary_user_uniq_id()},
    strategy_type(), conn()) :: Plug.Conn.t()


  def config_user_social_data({:ok, :edit_identity, updated_identity_info}, strategy_type, conn) do
    MishkaAuth.Strategy.registered_user_routing(updated_identity_info.user_id, conn, strategy_type, @auth_version)
  end

  def config_user_social_data({:ok, :add_identity, identity_info}, strategy_type, conn) do
    MishkaAuth.Strategy.registered_user_routing(identity_info.user_id, conn, strategy_type, @auth_version)
  end


  def config_user_social_data({:ok, :create_or_update_user, :save_temporary_social_data, temporary_user_uniq_id}, strategy_type, conn) do
    case MishkaAuth.RedisClient.get_data_of_singel_id(@temporary_table , temporary_user_uniq_id) do
      {:ok, :get_data_of_singel_id, user_temporary_data} ->
        MishkaAuth.Strategy.none_registered_user_routing(conn, user_temporary_data, temporary_user_uniq_id, 200, strategy_type)
      _ ->
        MishkaAuth.Strategy.failed_none_registered_user_routing(conn, %{error: "please try again. missing value."}, 404, strategy_type)
    end
  end

  def config_user_social_data(_, _, _) do
    {:error, :config_user_social_data, :none_user}
  end

end
