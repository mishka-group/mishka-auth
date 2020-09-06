defmodule MishkaAuthTest.Helper.PhoenixConverterTest do
  use ExUnit.Case
  use MishkaAuthWeb.ConnCase
  alias MishkaAuth.Helper.PhoenixConverter

  describe "Happy | Phoenix Converter (▰˘◡˘▰)" do
    test "store session" do
      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:test, "test")

        {:ok, :plug_request_with_session, "test"} = assert MishkaAuth.Extra.plug_request_with_session(PhoenixConverter.store_session(:test, "test", "/", conn, "test"), "info")
    end

    test "session redirect" do
      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:test, "test")

        {:ok, :plug_request_with_session, "test"} = assert MishkaAuth.Extra.plug_request_with_session(PhoenixConverter.session_redirect(conn, "/", "test", :info), "info")
    end

    test "render json" do
      conn = build_conn()
      {:ok, :plug_request, 200} = assert MishkaAuth.Extra.plug_request(PhoenixConverter.render_json(conn, %{name: "test"}, :ok, 200))
    end

    test "changeset redirect" do
      conn = build_conn()
      {:error, :add_user, changeset} = assert MishkaAuth.Client.Users.ClientUserQuery.add_user(%{email: "test"})

      %Plug.Conn{} = plug = assert PhoenixConverter.changeset_redirect(conn, changeset)

      {_atom, {_msg, [validation: _type]}} = assert List.first(plug.assigns.changeset.errors)
    end

    test "register data" do
      conn = build_conn()
      %Plug.Conn{} = plug = PhoenixConverter.register_data(conn, %{test: "test"}, Ecto.UUID.generate)

      %{test: "test"} = assert plug.assigns.social_data
    end

    test "drop session and get session with key" do
      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:test, "test")

        conn = PhoenixConverter.drop_session(conn, :test)

        {:error, :get_session, _key} = assert PhoenixConverter.get_session_with_key(conn, :test)
    end

    test "callback session and callback redirect" do
      conn =
        build_conn()
        |> bypass_through(MishkaAuthWeb.Router, :browser)
        |> get("/")
        |> put_session(:request_render, "refresh_token")


      alias MishkaAuthWeb.Router.Helpers
      {:ok, :plug_request, 302} =  MishkaAuth.Extra.plug_request(PhoenixConverter.callback_session(conn, Helpers, :auth_path, "code", :google))
    end
  end




  describe "UnHappy | Phoenix Converter ಠ╭╮ಠ" do
    test "render json" do
      conn = build_conn()
      {:ok, :plug_request, 400} = assert MishkaAuth.Extra.plug_request(PhoenixConverter.render_json(conn, %{name: "test"}, :error, 400))
    end
  end
end
