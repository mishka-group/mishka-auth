defmodule MishkaAuth.Extra do
  import Ecto.Changeset
  @doc """
    this function checks your UUID and pass a map.
  """
  @alphabet Enum.concat([?0..?9, ?A..?Z, ?a..?z])



  @spec valid_uuid(any) :: {:error, :valid_uuid} | {:ok, :valid_uuid, <<_::288>>}

  def valid_uuid(uuid) do
    case Ecto.UUID.cast(uuid) do
      {:ok, uuid} -> {:ok, :valid_uuid, uuid}
      _ ->  {:error, :valid_uuid}
    end
  end



  @spec randstring(integer) :: binary

  def randstring(count) do
    :rand.seed(:exsplus, :os.timestamp())
    Stream.repeatedly(&random_char_from_alphabet/0)
    |> Enum.take(count)
    |> List.to_string()
    |> String.upcase
  end

  defp random_char_from_alphabet() do
    Enum.random(@alphabet)
  end


  # this function can convert %{name: "shahryar", last_name: "tavakkoli"} to ["name", "shahryar", "last_name", "tavakkoli"]
  @spec map_to_single_list_with_string_key(map()) :: list(any)

  def map_to_single_list_with_string_key(params) do
    params
    |> Enum.map(fn {k, v} ->
      [Atom.to_string(k), v]
    end)
    |> Enum.reduce([], fn( items, list ) -> list ++ items end )
  end


  @spec list_to_map(any) :: map

  def list_to_map(params) do
    params
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] -> {a, b} end)
    |> Map.new
  end


  @spec strong_params(map, [any]) :: map

  def strong_params(params, allowed_fields) do
    Map.take(params, allowed_fields)
  end


  @spec get_changeset_error(Ecto.Changeset.t()) :: %{optional(atom) => [binary]}

  def get_changeset_error(changeset) do
    traverse_errors(changeset, fn {msg, opts} ->
       Enum.reduce(opts, msg, fn {key, _value}, acc ->
         String.replace(acc, "%{#{key}}", to_string(acc))
       end)
    end)
  end

  @spec get_github_username(binary) :: String.t()
  def get_github_username(user_profile_url) do
    String.split(user_profile_url, ~r{/})
    |> List.last
  end

  @spec plug_request(any) :: {:error, :plug_request} | {:ok, :plug_request, any}
  def plug_request(%Plug.Conn{} = plug) do
    case plug.status do
      number -> {:ok, :plug_request, number}
    end
  end

  def plug_request(_) do
    {:error, :plug_request}
  end

  @spec plug_request_with_session(any, any) :: {:ok, :plug_request_with_session, any}
  def plug_request_with_session(%Plug.Conn{} = plug, type) do
    case plug.private.phoenix_flash[type] do
      msg -> {:ok, :plug_request_with_session, msg}
    end
  end

  def plug_request_with_session(_) do
    {:error, :plug_request_with_session}
  end
end
