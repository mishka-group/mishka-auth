defmodule MishkaAuth.Client.Users.ClientToken do

  @type token() :: String.t() | binary
  @type params() :: map()


  @spec create_and_update_current_token(binary, map) ::
          {:ok, :create_and_update_current_token, binary}

  def create_and_update_current_token(id, params \\ %{}) do
    {:ok, token, _clime} = encode_and_sign_token(id, params, MishkaAuth.get_config_info(:user_jwt_token_expire_time))
    {:ok, :current_token, token}
    |> save_token_into_redis(id, MishkaAuth.get_config_info(:user_jwt_token_expire_time))

    {:ok, :create_and_update_current_token, token}
  end

  @spec create_and_save_access_token(binary, map) ::
          {:ok, :insert_or_update_into_redis}
          | {:ok, :access_token, any, any}
          | {:ok, :save_token_into_redis, :create, any, any}

  def create_and_save_access_token(id, params \\ %{}) do
    {:ok, token, clime} = encode_and_sign_token(id, params, MishkaAuth.get_config_info(:user_access_token_expire_time))
    {:ok, :access_token, token, clime}
    |> save_token_into_redis(id, MishkaAuth.get_config_info(:user_access_token_expire_time))
  end

  @spec create_and_save_refresh_token(binary, map) ::
          {:ok, :insert_or_update_into_redis}
          | {:ok, :access_token, any, any}
          | {:ok, :save_token_into_redis, :create, any, any}

  def create_and_save_refresh_token(id, params \\ %{}) do
    encode_and_sign_token(id, params, MishkaAuth.get_config_info(:user_refresh_token_expire_time))
    |> save_token_into_redis(id, MishkaAuth.get_config_info(:user_refresh_token_expire_time))
  end

  @spec refresh_token(binary, any) ::
          {:error, :refresh_token} | {:ok, :refresh_token, binary, map}

  def refresh_token(token, time) do
    case MishkaAuth.Guardian.refresh(token, ttl: {time, :minutes}) do
      {:ok, _old_token_and_clime, {new_token, new_clime}} -> {:ok, :refresh_token, new_token, new_clime}
      _ -> {:error, :refresh_token}
    end
  end

  @spec create_access_token(binary) :: {:error, any} | {:ok, binary, map}

  def create_access_token(id) do
    encode_and_sign_token(id, %{}, MishkaAuth.get_config_info(:user_access_token_expire_time))
  end

  @spec encode_and_sign_token(binary, map, any) :: {:error, any} | {:ok, binary, map}

  def encode_and_sign_token(id, params, time) do
    MishkaAuth.Guardian.encode_and_sign(%{id: "#{id}"}, Map.merge(%{some: "claim"}, params), token_type: "access",ttl: {time, :seconds})
  end

  @spec verify_token(binary) :: {:error, any} | {:ok, map}

  def verify_token(token) do
    MishkaAuth.Guardian.decode_and_verify(token)
  end

  @spec get_id_from_jwt_climes(nil | maybe_improper_list | map) :: {:ok, %{id: any}}

  def get_id_from_jwt_climes(climes) do
    MishkaAuth.Guardian.resource_from_claims(climes)
  end

  @spec save_token_into_redis(
          {:ok, any, any} | {:ok, :access_token | :refresh_token, token(), any},
          binary,
          any
        ) ::
          {:ok, :insert_or_update_into_redis}
          | {:ok, :access_token, token(), any}
          | {:ok, :save_token_into_redis, :create, token(), any}

  def save_token_into_redis({:ok, :refresh_token, new_token, _new_clime}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:refresh_token_table), id, %{token: new_token}, time)
  end


  def save_token_into_redis({:ok, :access_token, access_token, clime}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:access_token_table), id, %{token: access_token}, time)
    {:ok, :access_token, access_token, clime}
  end

  def save_token_into_redis({:ok, :current_token, new_token}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:token_table), id, %{token: new_token}, time)
  end

  # login refresh_token
  def save_token_into_redis({:ok, user_token, clime}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:refresh_token_table), id, %{token: user_token}, time)
    {:ok, :save_token_into_redis, :create, user_token, clime}
  end

  @spec valid_refresh_token(binary) ::
          {:error, :valid_refresh_token} | {:ok, :valid_refresh_token, binary, map}

  def valid_refresh_token(token) do
    with {:ok, _def_name, _token, _token_table, id} <- get_and_verify_token_on_redis(token, MishkaAuth.get_config_info(:refresh_token_table)),
    {:ok, :refresh_token, new_token, new_clime} = refresh_token <- refresh_token(token, MishkaAuth.get_config_info(:user_refresh_token_expire_time)) do
      save_token_into_redis(refresh_token, id, MishkaAuth.get_config_info(:user_refresh_token_expire_time))

      {:ok, :valid_refresh_token, new_token, new_clime}
    else
      _n ->
        {:error, :valid_refresh_token}
    end
  end


  @spec valid_user_token(binary) ::
          {:error, :valid_user_token} | {:ok, :create_and_update_current_token, binary}

  def valid_user_token(token) do
    with {:ok, _def_name, _token, _token_table, user_id} <- get_and_verify_token_on_redis(token, MishkaAuth.get_config_info(:token_table)) do
       create_and_update_current_token(user_id)
    else
      _n ->
        {:error, :valid_user_token}
    end
  end

  @spec verify_token(binary, any, :refresh_token) ::
          {:error, :verify_token, :access_token | :refresh_token}
          | {:ok, :verify_token, :refresh_token_and_access_token, binary}

  def verify_token(refresh_token, access_token, :refresh_token) do
    with  {:ok, :verify_token, :refresh_token, user_id} <- verify_token(refresh_token, :refresh_token),
          {:ok, :verify_token, :access_token, _access_token_user_id} <- verify_token(access_token, :access_token) do

         {:ok, :verify_token, :refresh_token_and_access_token, user_id}

     else
        {:error, :verify_token, :refresh_token} ->
         {:error, :verify_token, :refresh_token}

        {:error, :verify_token, :access_token} ->
         {:error, :verify_token, :access_token}
     end
   end

   @spec verify_token(binary, :access_token | :current_token | :refresh_token) ::
           {:error, :verify_token, :access_token | :current_token | :refresh_token}
           | {:ok, :verify_token, :access_token | :current_token | :refresh_token, binary}

   def verify_token(refresh_token, :refresh_token) do
     with {:ok, :get_and_verify_token_on_redis, _token, _token_table, user_id} <- get_and_verify_token_on_redis(refresh_token, MishkaAuth.get_config_info(:refresh_token_table)) do

         {:ok, :verify_token, :refresh_token, user_id}

     else
       _ ->
         {:error, :verify_token, :refresh_token}
     end
   end


   def verify_token(user_token, :current_token) do
    with {:ok, :get_and_verify_token_on_redis, _token, _token_table, user_id} <- get_and_verify_token_on_redis(user_token, MishkaAuth.get_config_info(:token_table) ) do

        {:ok, :verify_token, :current_token, user_id}
    else
      _ ->
        {:error, :verify_token, :current_token}
    end
  end


   def verify_token(access_token, :access_token) do
     with {:ok, :get_and_verify_token_on_redis, _token, _token_table, user_id} <- get_and_verify_token_on_redis(access_token, MishkaAuth.get_config_info(:access_token_table)) do

       {:ok, :verify_token, :access_token, user_id}

     else
        _ ->
         {:error, :verify_token, :access_token}
     end
   end


   @spec verify_and_update_token(Plug.Conn.t(), token(), token(), :refresh_token) :: Plug.Conn.t()

   def verify_and_update_token(conn, refresh_token, access_token, :refresh_token) do
    case verify_token(refresh_token, access_token, :refresh_token) do
      {:ok, :verify_token, :refresh_token_and_access_token, user_id} ->
        MishkaAuth.Strategy.registered_user_routing(user_id, conn, :refresh_token, 2)
      {:error, :verify_token, :refresh_token} ->
        MishkaAuth.Helper.PhoenixConverter.render_json(conn, %{error: "Invalid Refresh Token."}, :error, 401)
      {:error, :verify_token, :access_token} ->
        MishkaAuth.Helper.PhoenixConverter.render_json(conn, %{error: "Invalid Access Token."}, :error, 401)
    end
  end


  @spec verify_and_update_token(Plug.Conn.t(), token(), :current_token | :refresh_token) ::
          Plug.Conn.t()

  def verify_and_update_token(conn, refresh_token, :refresh_token) do
    case verify_token(refresh_token, :refresh_token) do
      {:ok, :verify_token, :refresh_token, user_id} ->
        MishkaAuth.Strategy.registered_user_routing(user_id, conn, :refresh_token, 2)
      {:error, :verify_token, :refresh_token} ->
        MishkaAuth.Helper.PhoenixConverter.render_json(conn, %{error: "Invalid Refresh Token."}, :error, 401)
    end
  end


  def verify_and_update_token(conn, current_token, :current_token) do
    case verify_token(current_token, :current_token)do
      {:ok, :verify_token, :current_token, user_id} ->
        MishkaAuth.Strategy.registered_user_routing(user_id, conn, :current_token, 2)
      {:error, :verify_token, :current_token} ->
        MishkaAuth.Helper.PhoenixConverter.drop_session(conn, :current_user)
        |> MishkaAuth.Helper.PhoenixConverter.session_redirect(MishkaAuth.get_config_info(:login_redirect), "Token expired. Please login.", :error)
    end
  end

  @spec get_and_verify_token_on_redis(token(), String.t()) ::
          {:error, :get_and_verify_token_on_redis}
          | {:ok, :get_and_verify_token_on_redis, binary, binary, binary}

  def get_and_verify_token_on_redis(token, token_table) do
    with {:ok, claims} <- verify_token(token),
    {:ok, %{id: id}} <- get_id_from_jwt_climes(claims),
    {:ok, :get_data_of_singel_id, %{"token" => redis_token}} <- MishkaAuth.RedisClient.get_data_of_singel_id(token_table, id),
    {:ok, :same_token_between_client_and_redis} <- same_token_between_client_and_redis(token, redis_token) do

      {:ok, :get_and_verify_token_on_redis, token, token_table, id}
    else
      _ -> {:error, :get_and_verify_token_on_redis}
    end
  end


  @spec same_token_between_client_and_redis(token(), token()) ::
          {:error, :same_token_between_client_and_redis}
          | {:ok, :same_token_between_client_and_redis}

  def same_token_between_client_and_redis(token, redis_token) do
    if token ===  redis_token, do: {:ok, :same_token_between_client_and_redis} , else: {:error, :same_token_between_client_and_redis}
  end

end
