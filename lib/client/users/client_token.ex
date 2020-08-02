defmodule MishkaAuth.Client.Users.ClientToken do

  @type token() :: String.t()
  @type params() :: map()


  def create_and_update_current_token(id, params \\ %{}) do
    {:ok, token, _clime} = encode_and_sign_token(id, params, MishkaAuth.get_config_info(:user_jwt_token_expire_time))
    {:ok, :current_token, token}
    |> save_token_into_redis(id, MishkaAuth.get_config_info(:user_jwt_token_expire_time))

    {:ok, :create_and_update_current_token, token}
  end


  def create_and_save_refresh_token(id, params \\ %{}) do
    encode_and_sign_token(id, params, MishkaAuth.get_config_info(:user_refresh_token_expire_time))
    |> save_token_into_redis(id, MishkaAuth.get_config_info(:user_refresh_token_expire_time))
  end

  def refresh_token(token, time) do
    case MishkaAuth.Guardian.refresh(token, ttl: {time, :minutes}) do
      {:ok, _old_token_and_clime, {new_token, new_clime}} -> {:ok, :refresh_token, new_token, new_clime}
      _ -> {:error, :refresh_token}
    end
  end

  def create_access_token(id) do
    encode_and_sign_token(id, %{}, MishkaAuth.get_config_info(:user_access_token_expire_time))
  end

  def encode_and_sign_token(id, params, time) do
    MishkaAuth.Guardian.encode_and_sign(%{id: "#{id}"}, Map.merge(%{some: "claim"}, params), token_type: "access",ttl: {time, :seconds})
  end

  def verify_token(token) do
    MishkaAuth.Guardian.decode_and_verify(token)
  end

  def get_id_from_jwt_climes(climes) do
    MishkaAuth.Guardian.resource_from_claims(climes)
  end

  def save_token_into_redis({:ok, :refresh_token, new_token, _new_clime}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:refresh_token_table), id, %{token: new_token}, time)
  end

  def save_token_into_redis({:ok, :current_token, new_token}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:token_table), id, %{token: new_token}, time)
  end

  def save_token_into_redis({:ok, user_token, _clime}, id, time) do
    MishkaAuth.RedisClient.insert_or_update_into_redis(MishkaAuth.get_config_info(:token_table), id, %{token: user_token}, time)
    {:ok, :save_token_into_redis, :create, user_token}
  end

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


  def valid_user_token(token) do
    with {:ok, _def_name, _token, _token_table, user_id} <- get_and_verify_token_on_redis(token, MishkaAuth.get_config_info(:token_table)) do
       create_and_update_current_token(user_id)
    else
      _n ->
        {:error, :valid_user_token}
    end
  end

  def verify_token(refresh_token, access_token, :refresh_token) do
    with {:ok, :get_and_verify_token_on_redis, _token, _token_table, user_id} <- get_and_verify_token_on_redis(refresh_token, MishkaAuth.get_config_info(:refresh_token_table)),
         {:ok, _access_claims} <- verify_token(access_token) do

         {:ok, :verify_token, :refresh_token, user_id}

     else
       {:error, :get_and_verify_token_on_redis} ->
         {:error, :verify_token, :refresh_token}
        _ ->
         {:error, :verify_token, :access_token}
     end
   end

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
     with {:ok, access_claims} <- verify_token(access_token),
         {:ok, %{id: user_id}} <- get_id_from_jwt_climes(access_claims) do
       {:ok, :verify_token, :access_token, user_id}
     else
        _ ->
         {:error, :verify_token, :access_token}
     end
   end


   def verify_and_update_token(conn, refresh_token, access_token, :refresh_token) do
    case verify_token(refresh_token, access_token, :refresh_token) do
      {:ok, :verify_token, :refresh_token, user_id} ->
        MishkaAuth.Strategy.registered_user_routing(user_id, conn, :refresh_token, 2)
      {:error, :verify_token, :refresh_token} ->
        MishkaAuth.Helper.PhoenixConverter.render_json(conn, %{error: "Invalid Refresh Token."}, :error, 401)
      {:error, :verify_token, :access_token} ->
        MishkaAuth.Helper.PhoenixConverter.render_json(conn, %{error: "Invalid Access Token."}, :error, 401)
    end
  end


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
