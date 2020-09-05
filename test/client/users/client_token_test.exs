defmodule MishkaAuthTest.Client.ClientTokenTest do
  use ExUnit.Case
  use MishkaAuthWeb.ConnCase

  alias MishkaAuth.Client.Users.ClientToken

  describe "Happy | client User Token (▰˘◡˘▰)" do
    test "create and update current token" do
      {:ok, :create_and_update_current_token, _token} = assert ClientToken.create_and_update_current_token(Ecto.UUID.generate, %{})
    end

    test "create and save access token" do
      {:ok, :access_token, _access_token, _clime} = assert ClientToken.create_and_save_access_token(Ecto.UUID.generate, %{})
    end

    test "create and save refresh token" do
      {:ok, :save_token_into_redis, :create, _user_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})
    end

    test "refresh_token" do
      {:ok, :save_token_into_redis, :create, user_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})
      {:ok, :refresh_token, _new_token, _new_clime} = assert ClientToken.refresh_token(user_token, 20000)
    end

    test "create access token" do
      {:ok, _token, _clime} = assert ClientToken.create_access_token(Ecto.UUID.generate)
    end


    test "encode and sign token" do
      {:ok, _token, _clime} = assert ClientToken.encode_and_sign_token(Ecto.UUID.generate, %{}, 20000)
    end

    test "verify token" do
      {:ok, token, _clime} = assert ClientToken.encode_and_sign_token(Ecto.UUID.generate, %{}, 20000)
      {:ok, _clime} = assert ClientToken.verify_token(token)
    end

    test "get id from jwt climes" do
      {:ok, _token, clime} = assert ClientToken.encode_and_sign_token(Ecto.UUID.generate, %{}, 20000)
      {:ok, %{id: _id}} = assert ClientToken.get_id_from_jwt_climes(clime)
    end

    test "save token into redis refresh_token" do
      id = Ecto.UUID.generate
      {:ok, user_token, _clime} = assert ClientToken.encode_and_sign_token(id, %{}, 20000)

      {:ok, :refresh_token, new_token, new_clime} = assert ClientToken.refresh_token(user_token, 20000)

      {:ok, :insert_or_update_into_redis} = assert ClientToken.save_token_into_redis({:ok, :refresh_token, new_token, new_clime}, id, 20000)
    end


    test "save token into redis access_token" do
      id = Ecto.UUID.generate
      {:ok, user_token, clime} = assert ClientToken.encode_and_sign_token(id, %{}, 20000)
      {:ok, :access_token, _access_token, _clime} = assert ClientToken.save_token_into_redis({:ok, :access_token, user_token, clime}, id, 20000)
    end

    test "save token into redis current_token" do
      id = Ecto.UUID.generate
      {:ok, new_token, _clime} = assert ClientToken.encode_and_sign_token(id, %{}, 20000)
      {:ok, :insert_or_update_into_redis} = assert ClientToken.save_token_into_redis({:ok, :current_token, new_token}, id, 2000)
    end

    test "save token into redis (:create)" do
      id = Ecto.UUID.generate
      {:ok, new_token, clime} = assert ClientToken.encode_and_sign_token(id, %{}, 20000)
      {:ok, :save_token_into_redis, :create, _user_token, _clime} = assert ClientToken.save_token_into_redis({:ok, new_token, clime}, id, 2000)
    end

    test "valid_refresh_token" do
      {:ok, :save_token_into_redis, :create, user_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :valid_refresh_token, _new_token, _new_clime} = assert ClientToken.valid_refresh_token(user_token)
    end

    test "valid user token" do
      {:ok, :create_and_update_current_token, token} = assert ClientToken.create_and_update_current_token(Ecto.UUID.generate, %{})
      {:ok, :create_and_update_current_token, _token} = assert ClientToken.valid_user_token(token)
    end

    test "verify token(refresh_token, access_token)" do
      {:ok, :save_token_into_redis, :create, refresh_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :access_token, access_token, _clime} = assert ClientToken.create_and_save_access_token(Ecto.UUID.generate, %{})

      {:ok, :verify_token, :refresh_token_and_access_token, _user_id} = assert ClientToken.verify_token(refresh_token, access_token, :refresh_token)
    end

    test "verify_token(:refresh_token, :refresh_token)" do
      {:ok, :save_token_into_redis, :create, refresh_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :verify_token, :refresh_token, _user_id} = assert ClientToken.verify_token(refresh_token, :refresh_token)
    end

    test "verify_token(user_token, :current_token)" do
      {:ok, :create_and_update_current_token, user_token} = assert ClientToken.create_and_update_current_token(Ecto.UUID.generate, %{})

      {:ok, :verify_token, :current_token, _user_id} = assert ClientToken.verify_token(user_token, :current_token)
    end

    test "verify_token(access_token, :access_token)" do
      {:ok, :access_token, access_token, _clime} = assert ClientToken.create_and_save_access_token(Ecto.UUID.generate, %{})

      {:ok, :verify_token, :access_token, _user_id} = assert ClientToken.verify_token(access_token, :access_token)
    end

    test "test verify and update token with plug" do
      conn = build_conn()
      {:ok, :access_token, access_token, _clime} = assert ClientToken.create_and_save_access_token(Ecto.UUID.generate, %{})

      {:ok, :save_token_into_redis, :create, refresh_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :plug_request, 200} = assert MishkaAuth.Extra.plug_request(ClientToken.verify_and_update_token(conn, refresh_token, access_token, :refresh_token))
    end

    test "verify and update token (:refresh_token)" do
      conn = build_conn()

      {:ok, :save_token_into_redis, :create, refresh_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :plug_request, 200} = assert MishkaAuth.Extra.plug_request(ClientToken.verify_and_update_token(conn, refresh_token, :refresh_token))
    end

    test "verify and update token (:current_token)" do
      {:ok, :create_and_update_current_token, current_token} = assert ClientToken.create_and_update_current_token(Ecto.UUID.generate, %{})

      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:current_token, current_token)


      {:ok, :plug_request_with_session, "Successfully authenticated."} = assert MishkaAuth.Extra.plug_request_with_session(ClientToken.verify_and_update_token(conn, current_token, :current_token), "info")
    end

    test "get and verify token on redis" do
      {:ok, :access_token, access_token, _clime} = assert ClientToken.create_and_save_access_token(Ecto.UUID.generate, %{})

      {:ok, :get_and_verify_token_on_redis, _token, _token_table, _id} = assert ClientToken.get_and_verify_token_on_redis(access_token, "access_token")
    end

    test "delete user token(user_id, :refresh_token)" do
      id = Ecto.UUID.generate
      {:ok, :save_token_into_redis, :create, _user_token, _clime} = assert ClientToken.create_and_save_refresh_token(id, %{})

      {:ok, :delete_record_of_redis, "The record is deleted"} = assert ClientToken.delete_user_token(id, :refresh_token)
    end

    test "delete user token(user_id, :access_token)" do
      id = Ecto.UUID.generate
      {:ok, :access_token, _access_token, _clime} = assert ClientToken.create_and_save_access_token(id, %{})

      {:ok, :delete_record_of_redis, "The record is deleted"} = assert ClientToken.delete_user_token(id, :access_token)
    end

    test "delete user token(user_id, :user_token)" do
      id = Ecto.UUID.generate
      {:ok, :create_and_update_current_token, _token} = assert ClientToken.create_and_update_current_token(id, %{})


      {:ok, :delete_record_of_redis, "The record is deleted"} = assert ClientToken.delete_user_token(id, :user_token)
    end

    test "delete user token(user_id, :all_token)" do
      id = Ecto.UUID.generate

      {:ok, :access_token, _access_token, _clime} = assert ClientToken.create_and_save_access_token(id, %{})

      {:ok, :create_and_update_current_token, _token} = assert ClientToken.create_and_update_current_token(id, %{})

      {:ok, :save_token_into_redis, :create, _user_token, _clime} = assert ClientToken.create_and_save_refresh_token(id, %{})



      [
        {:ok, :delete_record_of_redis, "The record is deleted"},
        {:ok, :delete_record_of_redis, "The record is deleted"},
        {:ok, :delete_record_of_redis, "The record is deleted"}
      ] = assert ClientToken.delete_user_token(id, :all_token)
    end
  end







  describe "UnHappy | client User Token ಠ╭╮ಠ" do
    test "refresh_token" do
      {:error, :refresh_token} = assert ClientToken.refresh_token("user_token", 20000)
    end

    test "verify token" do
      {:error, _clime} = assert ClientToken.verify_token("token")
    end

    test "valid refresh token" do
      id = Ecto.UUID.generate
      {:ok, user_token, _clime} = assert ClientToken.encode_and_sign_token(id, %{}, 20000)
      {:error, :valid_refresh_token} = assert ClientToken.valid_refresh_token(user_token)
    end

    test "valid user token" do
      {:error, :valid_user_token} = assert ClientToken.valid_user_token("token")
    end

    test "verify_token(refresh_token, access_token)" do
      {:error, :verify_token, :refresh_token} = assert ClientToken.verify_token("refresh_token", "access_token", :refresh_token)
    end

    test "verify_token(:refresh_token, :refresh_token)" do
      {:error, :verify_token, :refresh_token} = assert ClientToken.verify_token("refresh_token", :refresh_token)
    end

    test "verify_token(user_token, :current_token)" do
      {:error, :verify_token, :current_token} = assert ClientToken.verify_token("user_token", :current_token)
    end

    test "verify_token(access_token, :access_token)" do
      {:error, :verify_token, :access_token} = assert ClientToken.verify_token("access_token", :access_token)
    end

    test "test verify and update token with plug" do
      conn = build_conn()

      {:ok, :save_token_into_redis, :create, refresh_token, _clime} = assert ClientToken.create_and_save_refresh_token(Ecto.UUID.generate, %{})

      {:ok, :plug_request, 401} = assert MishkaAuth.Extra.plug_request(ClientToken.verify_and_update_token(conn, refresh_token, "access_token", :refresh_token))
    end

    test "verify and update token (:refresh_token)" do
      conn = build_conn()

      {:ok, :plug_request, 401} = assert MishkaAuth.Extra.plug_request(ClientToken.verify_and_update_token(conn, "refresh_token", :refresh_token))
    end

    test "verify and update token (:current_token)" do
      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:current_token, "current_token")


      {:ok, :plug_request_with_session, "Token expired. Please login."} = assert MishkaAuth.Extra.plug_request_with_session(ClientToken.verify_and_update_token(conn, "current_token", :current_token), "error")
    end

    test "get and verify token on redis" do
      {:error, :get_and_verify_token_on_redis} = assert ClientToken.get_and_verify_token_on_redis("access_token", "access_token")
    end

    test "delete user token(user_id, :refresh_token)" do
      {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"} = assert ClientToken.delete_user_token(Ecto.UUID.generate, :refresh_token)
    end

    test "delete user token(user_id, :access_token)" do
      {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"} = assert ClientToken.delete_user_token(Ecto.UUID.generate, :access_token)
    end

    test "delete user token(user_id, :user_token)" do
      {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"} = assert ClientToken.delete_user_token(Ecto.UUID.generate, :user_token)
    end

    test "delete user token(user_id, :all_token)" do
      [
        {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"},
        {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"},
        {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"}
      ] = assert ClientToken.delete_user_token(Ecto.UUID.generate, :all_token)
    end
  end
end
