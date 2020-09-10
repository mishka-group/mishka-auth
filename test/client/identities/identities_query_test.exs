defmodule MishkaAuthTest.Client.IdentitiesQueryTest do
  use ExUnit.Case
  alias MishkaAuth.Client.Identity.ClientIdentityQuery
  alias MishkaAuth.Client.Users.ClientUserQuery

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MishkaAuth.get_config_info(:repo))
  end

  @true_user_parameters %{
    name: "username#{String.downcase(MishkaAuth.Extra.randstring(8))}",
    lastname: "userlastname#{String.downcase(MishkaAuth.Extra.randstring(8))}",
    username: "usernameuniq#{String.downcase(MishkaAuth.Extra.randstring(8))}",
    email: "user_name_#{String.downcase(MishkaAuth.Extra.randstring(8))}@gmail.com",
    password: "passTe1st#{MishkaAuth.Extra.randstring(10)}",
    status: 1,
  }

  @true_identity %{
    identity_provider: :google,
    uid: Ecto.UUID.generate(),
    token: Ecto.UUID.generate()
  }

  describe "Happy | Identity Query basic CRUD (▰˘◡˘▰)" do
    test "find identity" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))

      {:ok, :find_identity, _find_identity_info} = assert ClientIdentityQuery.find_identity(identity_info.id)
    end

    test "add identity" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, _identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))
    end

    test "edit identity" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))


      {:ok, :edit_identity, _updated_identity_info} = assert ClientIdentityQuery.edit_identity(identity_info.id, @true_identity)
    end

    test "delete_identity" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))

      {:ok, :delete_identity, _struct} = assert ClientIdentityQuery.delete_identity(identity_info.id)
    end

    test "find user identity" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, _identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))

      {:ok, :find_user_identity, _identity} = assert ClientIdentityQuery.find_user_identity(user_info.id, "google")
    end

    test "find user identity with uid" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))

      {:ok, :find_user_identity_with_uid, _identity, _provider} = assert ClientIdentityQuery.find_user_identity_with_uid(identity_info.uid, :google)
    end

    test "find user identities" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      {:ok, :add_identity, identity_info} = assert ClientIdentityQuery.add_identity(@true_identity |> Map.merge(%{user_id: user_info.id}))

      [_something] = assert ClientIdentityQuery.find_user_identities(identity_info.user_id)
    end

    test "add with user redis data" do
      {:ok, :add_user, user_info} = assert ClientUserQuery.add_user(@true_user_parameters)

      MishkaAuth.RedisClient.insert_or_update_into_redis(
        "temporary_user_data",
        user_info.id,
        @true_identity |> Map.merge(%{user_id: user_info.id, provider: "google"}), "18000"
      )

      {:ok, :add_identity, _identity_info} = assert ClientIdentityQuery.add_with_user_redis_data(user_info.id, user_info.id)
    end
  end











  describe "UnHappy | Identity Query basic CRUD ಠ╭╮ಠ" do
    test "find identity" do
      {:error, :find_identity} = assert ClientIdentityQuery.find_identity(Ecto.UUID.generate)
    end

    test "add identity" do
      {:error, :add_identity, _changeset} = assert ClientIdentityQuery.add_identity(@true_identity)
    end

    test "edit identity" do
      {:error, :edit_identity, :identity_doesnt_exist} = assert ClientIdentityQuery.edit_identity(Ecto.UUID.generate, %{name: "test"})
    end

    test "edit identity fulse id" do
      {:error, :edit_identity, :identity_doesnt_exist} = assert ClientIdentityQuery.edit_identity("test", @true_identity)
    end

    test "delete identity" do
      {:error, :delete_identity, :user_doesnt_exist} = assert ClientIdentityQuery.delete_identity(Ecto.UUID.generate)
    end

    test "find user identity" do
      {:error, :find_user_identity, _provider} = assert ClientIdentityQuery.find_user_identity(Ecto.UUID.generate, "google")
    end

    test "find user identity with uid" do
      {:error, :find_user_identity_with_uid, _provider} = assert ClientIdentityQuery.find_user_identity_with_uid(Ecto.UUID.generate, "google")
    end

    test "find user identities" do
      [] = assert ClientIdentityQuery.find_user_identities(Ecto.UUID.generate)
    end

    test "add with user redis data" do
      {:error, :add_with_user_redis_data} = assert ClientIdentityQuery.add_with_user_redis_data(Ecto.UUID.generate, Ecto.UUID.generate)
    end
  end
end
