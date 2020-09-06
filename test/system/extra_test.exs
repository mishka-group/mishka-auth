defmodule MishkaAuthTest.System.Extra do
  use ExUnit.Case

  alias MishkaAuth.Extra
  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(MishkaAuth.get_config_info(:repo))
  end

  @true_user_parameters %{
    lastname: "userlastname#{MishkaAuth.Extra.randstring(8)}",
    username: "usernameuniq#{MishkaAuth.Extra.randstring(8)}",
    email: "user_name_#{MishkaAuth.Extra.randstring(8)}@gmail.com",
    password: "#{MishkaAuth.Extra.randstring(10)}",
    status: 1,
    unconfirmed_email: "user_name_#{MishkaAuth.Extra.randstring(8)}@gmail.com"
  }


  describe "Happy | System Extra (▰˘◡˘▰)" do
    test "valid uuid" do
      {:ok, :valid_uuid, _uuid} = assert Extra.valid_uuid(Ecto.UUID.generate)
    end

    test "randstring" do
      8 = assert Extra.randstring(8) |> String.length
    end

    test "map to single list with string key" do
      ["last_name", "test", "name", "test"] = assert Extra.map_to_single_list_with_string_key(%{name: "test", last_name: "test"})
    end

    test "list to map" do
      %{"last_name" => "test", "name" => "test"} = assert Extra.list_to_map(["last_name", "test", "name", "test"])
    end

    test "strong params" do
      params = %{"last_name" => "test", "name" => "test"}

      %{"last_name" => "test"} = assert Extra.strong_params(params, ["last_name"])
    end

    test "get changeset error" do
      {:error, :add_user, changeset} = assert MishkaAuth.Client.Users.ClientUserQuery.add_user(@true_user_parameters)
      %{name: [_msg]} = assert Extra.get_changeset_error(changeset)
    end

    test "get github username" do
      user_profile_url = "https://test.com/profile/mishka_auth"
      "mishka_auth" = assert Extra.get_github_username(user_profile_url)
    end

    test "plug request" do
      plug = %Plug.Conn{
        status: 100
      }
      {:ok, :plug_request, 100} = assert Extra.plug_request(plug)
    end

    test "plug request with session" do
      plug = %Plug.Conn{
        private: %{
          phoenix_flash: %{
            "info" => "test"
          }
        }
      }
      {:ok, :plug_request_with_session, "test"} = assert Extra.plug_request_with_session(plug, "info")
    end
  end







  describe "UnHappy | System Extra ಠ╭╮ಠ" do
    test "valid uuid" do
      {:error, :valid_uuid} = assert Extra.valid_uuid("test")
    end

    test "plug request" do
      plug = %{}
      {:error, :plug_request} = assert Extra.plug_request(plug)
    end

    test "plug request with session" do
      {:error, :plug_request_with_session} = assert Extra.plug_request_with_session(%{}, "test")
    end
  end


end
