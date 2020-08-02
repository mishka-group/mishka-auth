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
  def map_to_single_list_with_string_key(params) do
    params
    |> Enum.map(fn {k, v} ->
      [Atom.to_string(k), v]
    end)
    |> Enum.reduce([], fn( items, list ) -> list ++ items end )
  end


  def list_to_map(params) do
    params
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] -> {a, b} end)
    |> Map.new
  end


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
end
