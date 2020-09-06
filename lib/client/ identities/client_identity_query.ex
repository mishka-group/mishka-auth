defmodule MishkaAuth.Client.Identity.ClientIdentityQuery do


  import  Ecto.Query
  alias MishkaAuth.Helper.Db
  alias MishkaAuth.Client.Identity.ClientIdentitySchema

  @moduledoc """
    this module helps us to handle users identity and connect to identity database and extrenal site to login.
  """


  @type user_id()  :: Ecto.UUID.t
  @type uid()  :: Ecto.UUID.t
  @type provider() :: String.t() | atom()


  @spec find_identity(uid) :: {:error, :find_identity} | {:ok, :find_identity, Ecto.Schema.t()}

  def find_identity(id) do
    case Db.repo.get(ClientIdentitySchema, id) do
      nil -> {:error, :find_identity}
      identity_info -> {:ok, :find_identity, identity_info}
    end
  end


  @doc """
    this function insers your identity
  """
  @spec add_identity(map()) ::
  {:error, :add_identity, Ecto.Changeset.t()} | {:ok, :add_identity, Ecto.Schema.t()}

  def add_identity(attrs) do
    add = %ClientIdentitySchema{}
    |> ClientIdentitySchema.changeset(attrs)
    |> Db.repo.insert()
    case add do
      {:ok, identity_info}    -> {:ok, :add_identity, identity_info}
      {:error, changeset}     -> {:error, :add_identity, changeset}
    end
  end



  # Repo update function to convert error to map, atom
  @spec update_identity(Ecto.Schema.t(), map()) ::
            {:ok, :update_identity, Ecto.Schema.t()}
          | {:error, :update_identity, Ecto.Changeset.t()}

  defp update_identity(old_data, attrs) do
    update = ClientIdentitySchema.changeset(old_data, attrs)
    |> Db.repo.update
    case update do
      {:ok, identity_info}    -> {:ok, :update_identity, identity_info}
      {:error, changeset}     -> {:error, :update_identity, changeset}
    end
  end



  @doc """
    with this function you can update and edit user identity with identity system id
  """
  @spec edit_identity(uid(), map()) ::
          {:error, :edit_identity, :identity_doesnt_exist}
          | {:ok, :edit_identity, Ecto.Schema.t()}
          | {:error, :edit_identity, :data_input_problem, Ecto.Changeset.t()}

  def edit_identity(id, attrs) do
    with {:ok, :valid_uuid, identity_id} <- MishkaAuth.Extra.valid_uuid(id),
         {:ok, :find_identity, identity_info} <- find_identity(identity_id),
         {:ok, :update_identity, updated_identity_info} <- update_identity(identity_info, attrs) do


          {:ok, :edit_identity, updated_identity_info}
    else
      {:error, :valid_uuid} ->
        {:error, :edit_identity, :identity_doesnt_exist}

        {:error, :update_identity, changeset} ->
          {:error, :edit_identity, :data_input_problem, changeset}
      _ ->
        {:error, :edit_identity, :identity_doesnt_exist}
    end
  end

  # convert Db.repo.delete to atom
  @spec remove_identity(Ecto.Schema.t()) :: {:error, :remove_identity, Ecto.Changeset.t()} | {:ok, :remove_identity, Ecto.Schema.t()}

  defp remove_identity(user_info) do
    case Db.repo.delete(user_info) do
      {:ok, struct}       -> {:ok, :remove_identity, struct}
      {:error, changeset} -> {:error, :remove_identity, changeset}
    end
  end


  @doc """
    with this function you can delete identity with identity_id
  """

  @spec delete_identity(uid()) ::
          {:error, :delete_identity, :user_doesnt_exist}
          | {:ok, :delete_identity, Ecto.Schema.t()}
          | {:error, :edit_user, :data_input_problem, Ecto.Changeset.t()}
          | {:error, :delete_identity, :forced_to_delete}


  def delete_identity(id) do
    try do
      with {:ok, :valid_uuid, identity_id} <- MishkaAuth.Extra.valid_uuid(id),
          {:ok, :find_identity, identity_info} <- find_identity(identity_id),
          {:ok, :remove_identity, struct} <- remove_identity(identity_info) do

            {:ok, :delete_identity, struct}
      else
        {:error, :valid_uuid} ->

          {:error, :delete_identity, :user_doesnt_exist}

        {:error, :remove_identity, changeset} ->
            {:error, :edit_user, :data_input_problem, changeset}
        _ ->

          {:error, :delete_identity, :user_doesnt_exist}
      end
    rescue
      _e in Ecto.ConstraintError ->
        {:error, :delete_identity, :forced_to_delete}
    end
  end



  @doc """
    find user identity with user_id and provider
  """
  @spec find_user_identity(user_id(), provider()) ::
          {:error, :find_user_identity, provider()} | {:ok, :find_user_identity, Ecto.Schema.t()}

  def find_user_identity(user_id, provider) do
    query = from u in ClientIdentitySchema,
        where: u.user_id == ^user_id,
        where: u.identity_provider == ^provider,
        select: %{
          id: u.id,
          identity_provider: u.identity_provider,
          uid: u.uid,
          token: u.token,
          user_id: u.user_id
        }
    case Db.repo.one(query) do
      nil       -> {:error, :find_user_identity, provider}
      identity  -> {:ok, :find_user_identity, identity}
    end
  end


  @doc """
    find user identity with identity_id and provider
  """
  @spec find_user_identity_with_uid(uid(), provider()) ::
          {:error, :find_user_identity_with_uid, provider()}
          | {:ok, :find_user_identity_with_uid, Ecto.Schema.t(), provider()}

  def find_user_identity_with_uid(uid, provider) do
    query = from u in ClientIdentitySchema,
        where: u.uid == ^uid,
        where: u.identity_provider == ^provider,
        select: %{
          id: u.id,
          identity_provider: u.identity_provider,
          uid: u.uid,
          token: u.token,
          user_id: u.user_id
        }
    case Db.repo.one(query) do
      nil       -> {:error, :find_user_identity_with_uid, provider}
      identity  -> {:ok, :find_user_identity_with_uid, identity, provider}
    end
  end

  @spec find_user_identities(uid()) :: list(map() | any())
  def find_user_identities(user_id) do
    query = from u in ClientIdentitySchema,
        where: u.user_id == ^user_id,
        select: %{
          id: u.id,
          identity_provider: u.identity_provider,
          uid: u.uid,
          token: u.token,
          user_id: u.user_id
        }
    Db.repo.all(query)
  end

  @spec add_with_user_redis_data(binary, any) ::
          {:error, :add_with_user_redis_data}
          | {:error, :add_identity, Ecto.Changeset.t()}
          | {:ok, :add_identity, %{optional(atom) => any}}

  def add_with_user_redis_data(temporary_id, user_id) do
    case MishkaAuth.RedisClient.get_data_of_singel_id(MishkaAuth.get_config_info(:temporary_table) , temporary_id) do
      {:ok, :get_data_of_singel_id, user_temporary_data} ->
        add_identity(%{
          user_id: user_id,
          identity_provider: user_temporary_data["provider"],
          uid: "#{user_temporary_data["uid"]}",
          token: "#{user_temporary_data["token"]}"
        })
      _ ->
        {:error, :add_with_user_redis_data}
    end
  end
end
