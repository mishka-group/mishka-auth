defmodule MishkaAuth.Client.Users.ClientUserQuery do

  @type username() :: String.t()
  @type password() :: String.t()
  @type email() :: String.t()
  @type data_uuid() :: Ecto.UUID.t
  @type unconfirmed_email() :: email() | nil

  @register_params ["name", "lastname", "username", "email", "password"]

 @moduledoc """
    this module helps us to handle users and connect to users database.
  """

  @topic inspect(__MODULE__)

  alias MishkaAuth.Helper.Db
  alias MishkaAuth.Client.Users.ClientUserSchema
#   alias MishkaAuth.Guardian




  @doc """
    this function starts push notification in this module.
  """
  @spec subscribe :: :ok | {:error, any}

  def subscribe do
    Phoenix.PubSub.subscribe(MishkaAuth.get_config_info(:pub_sub), @topic)
  end



  # this function converts error which is sent by user for showing in real-time app.
  defp notify_subscribers({:error, reason}, event) do
    {:error, event, reason}
  end

  defp notify_subscribers({:ok, result}, event) do
    Phoenix.PubSub.broadcast(MishkaAuth.get_config_info(:pub_sub), @topic, {__MODULE__, event, result})
    Phoenix.PubSub.broadcast(MishkaAuth.get_config_info(:pub_sub), @topic <> "#{result.id}", {__MODULE__, event, result})
  end



  @doc """
    this function accepts info which is created by map and adds user in Users table.
  """
  @spec add_user(map()) ::
  {:error, :add_user, Ecto.Changeset.t()} | {:ok, :add_user, Ecto.Schema.t()}

  def add_user(attrs) do
    add = %ClientUserSchema{}
    |> ClientUserSchema.changeset(attrs)
    |> Db.repo.insert()
    notify_subscribers(add, [:user, :add_user])
    case add do
      {:ok, user_info}    -> {:ok, :add_user, user_info}
      {:error, changeset}     -> {:error, :add_user, changeset}
    end
  end




  @spec update_user(Ecto.Schema.t(), map()) ::
                {:error, :update_user, Ecto.Changeset.t()} |
                {:ok, :update_user, Ecto.Schema.t()}

  defp update_user(old_data, attrs) do
    update = ClientUserSchema.changeset(old_data, attrs)
    |> Db.repo.update
    case update do
      {:ok, user_info}    -> {:ok, :update_user, user_info}
      {:error, changeset}     -> {:error, :update_user, changeset}
    end
  end


  @doc """
    this function accepts info which is created by map and updates user in Users table.
  """
  @spec edit_user(data_uuid(), map()) ::
  {:error, :edit_user, :user_doesnt_exist}
  | {:ok, :edit_user, Ecto.Schema.t()}
  | {:error, :edit_user, :data_input_problem, Ecto.Changeset.t()}

  def edit_user(id, attrs) do
    with {:ok, :valid_uuid, user_id} <- MishkaAuth.Extra.valid_uuid(id),
         {:ok, :find_user_with_user_id, user_info} <- find_user_with_user_id(user_id),
         {:ok, :update_user, updated_user_info} <- update_user(user_info, attrs) do


          notify_subscribers({:ok, updated_user_info}, [:user, :edit_user])
          {:ok, :edit_user, updated_user_info}
    else
      {:error, :valid_uuid} ->
        notify_subscribers({:error, :user_doesnt_exist}, [:user, :edit_user])
        {:error, :edit_user, :user_doesnt_exist}

        {:error, :update_user, changeset} ->
          {:error, :edit_user, :data_input_problem, changeset}
      _ ->
        notify_subscribers({:error, :user_doesnt_exist}, [:user, :edit_user])
        {:error, :edit_user, :user_doesnt_exist}
    end
  end




  # convert Db.repo.delete to atom
  @spec remove_user(Ecto.Schema.t()) ::
          {:error, :remove_user, Ecto.Changeset.t()} | {:ok, :remove_user, Ecto.Schema.t()}

  defp remove_user(user_info) do
    case Db.repo.delete(user_info) do
      {:ok, struct}       -> {:ok, :remove_user, struct}
      {:error, changeset} -> {:error, :remove_user, changeset}
    end
  end



  @doc """
    this function accepts id which was created and deletes user in Users table.
  """

  @spec delete_user(data_uuid()) ::
          {:error, :delete_user, :user_doesnt_exist}
          | {:ok, :delete_user, Ecto.Schema.t()}
          | {:error, :edit_user, :data_input_problem, Ecto.Changeset.t()}
          | {:error, :delete_user, :forced_to_delete}


  def delete_user(id) do
    try do
      with {:ok, :valid_uuid, user_id} <- MishkaAuth.Extra.valid_uuid(id),
          {:ok, :find_user_with_user_id, user_info} <- find_user_with_user_id(user_id),
          {:ok, :remove_user, struct} <- remove_user(user_info) do

            notify_subscribers({:ok, struct}, [:user, :delete_user])
            {:ok, :delete_user, struct}
      else
        {:error, :valid_uuid} ->
          notify_subscribers({:error, :user_doesnt_exist}, [:user, :delete_user])
          {:error, :delete_user, :user_doesnt_exist}

        {:error, :remove_user, changeset} ->
            {:error, :edit_user, :data_input_problem, changeset}
        _ ->
          notify_subscribers({:error, :user_doesnt_exist}, [:user, :delete_user])
          {:error, :delete_user, :user_doesnt_exist}
      end
    rescue
      _e in Ecto.ConstraintError -> {:error, :delete_user, :forced_to_delete}
    end
  end





  @doc """
    get user info with mail
  """
  @spec find_user_with_email(email()) ::
          {:error, :find_user_with_email} | {:ok, :find_user_with_email, Ecto.Schema.t()}
  def find_user_with_email(email) do
    case  Db.repo.get_by(ClientUserSchema, email: "#{email}") do
      nil -> {:error, :find_user_with_email}
      user_info -> {:ok, :find_user_with_email, user_info}
    end
  end


  @doc """
    get user info with username
  """
  @spec find_user_with_username(username()) ::
  {:error, :find_user_with_username} | {:ok, :find_user_with_username, Ecto.Schema.t()}

  def find_user_with_username(username) do
    case Db.repo.get_by(ClientUserSchema, username: "#{username}") do
      nil -> {:error, :find_user_with_username}
      user_info -> {:ok, :find_user_with_username, user_info}
    end
  end


  @doc """
    get user info with id
  """
  @spec find_user_with_user_id(data_uuid()) ::
  {:error, :find_user_with_user_id} | {:ok, :find_user_with_user_id, Ecto.Schema.t()}

  def find_user_with_user_id(id) do
    case Db.repo.get(ClientUserSchema, id) do
      nil -> {:error, :find_user_with_user_id}
      user_info -> {:ok, :find_user_with_user_id, user_info}
    end
  end

  @doc """
    this function has two job that can check user existed and user activated. it uses email for this
  """
  @spec is_user_activated?(email()) ::
          {:error, :is_user_activated?, :user_not_activated | :user_not_found}
          | {:ok, :is_user_activated?, Ecto.Schema.t()}


  def is_user_activated?(email) do
    with {:ok, :find_user_with_email, user_info} <- find_user_with_email(email),
         {:ok, :is_unconfirmed_email_nil} <- is_unconfirmed_email_nil?(user_info.unconfirmed_email) do

          {:ok, :is_user_activated?, user_info}
    else
      {:error, :find_user_with_email}      -> {:error, :is_user_activated?, :user_not_found}
      {:error, :is_unconfirmed_email_nil}  -> {:error, :is_user_activated?, :user_not_activated}
    end
  end



  @doc """
    this function has two job that can check user existed and user activated. it uses id for this
  """
  @spec is_user_activated_with_id?(data_uuid()) ::
          {:error, :is_user_activated_with_id?, :user_not_activated | :user_not_found}
          | {:ok, :is_user_activated_with_id, Ecto.Schema.t()}


  def is_user_activated_with_id?(id) do
    with {:ok, :find_user_with_user_id, user_info} <- find_user_with_user_id(id),
         {:ok, :is_unconfirmed_email_nil} <- is_unconfirmed_email_nil?(user_info.unconfirmed_email) do

         {:ok, :is_user_activated_with_id?, user_info}
    else
      {:error, :find_user_with_user_id}     -> {:error, :is_user_activated_with_id?, :user_not_found}
      {:error, :is_unconfirmed_email_nil}   -> {:error, :is_user_activated_with_id?, :user_not_activated}
    end
  end


  #  convert nil or string unconfirmed_email to atom
  @spec is_unconfirmed_email_nil?(unconfirmed_email()) ::
            {:ok, :is_unconfirmed_email_nil}
          | {:error, :is_unconfirmed_email_nil}

  defp is_unconfirmed_email_nil?(unconfirmed_email) do
    case unconfirmed_email do
      nil -> {:ok, :is_unconfirmed_email_nil}
      _ -> {:error, :is_unconfirmed_email_nil}
    end
  end


  @spec update_user_password(Ecto.Schema.t(), map()) ::
                      {:error, :update_user_password, Ecto.Changeset.t()} |
                      {:ok, :update_user_password, Ecto.Schema.t()}

  defp update_user_password(old_data, attrs) do
    update = ClientUserSchema.change_password_changeset(old_data, attrs)
    |> Db.repo.update
    case update do
      {:ok, user_update_info}     -> {:ok, :update_user_password, user_update_info}
      {:error, changeset}         -> {:error, :update_user_password, changeset}
    end
  end



  @spec edit_user_password(email(), map()) ::
          {:error, :edit_user_password, :user_not_found}
          | {:ok, :edit_user_password, Ecto.Schema.t()}
          | {:error, :edit_user_password, :data_input_problem, Ecto.Changeset.t()}

  @doc """
    edit user password with his email
  """


  def edit_user_password(email, attrs) do
    with {:ok, :find_user_with_email, user_info} <- find_user_with_email(email),
         {:ok, :update_user_password, user_update_info} <- update_user_password(user_info, attrs) do

      {:ok, :edit_user_password, user_update_info}
    else
      {:error, :find_user_with_email} -> {:error, :edit_user_password, :user_not_found}

      {:error, :update_user_password, changeset} -> {:error, :edit_user_password, :data_input_problem, changeset}
    end
  end




  @spec edit_user_verified_email(email()) ::
          {:ok, :edit_user_verified_email} | {:error, :edit_user_password, :user_not_found}

  @doc """
    systematic user activation
  """
  def edit_user_verified_email(email) do
    with {:ok, :find_user_with_email, user_info} <- find_user_with_email(email)do

      Ecto.Changeset.change(user_info, %{unconfirmed_email: nil})
      |> Db.repo.update

      {:ok, :edit_user_verified_email}
    else
      {:error, :find_user_with_email} -> {:error, :edit_user_password, :user_not_found}
    end
  end



  @doc """
    this function can help you check user password is valid or not.
  """
  @spec valid_password(Ecto.Schema.t(), password()) :: {:error, :valid_password} | {:ok, :valid_password}
  def valid_password(user_info, password) do
    case Bcrypt.check_pass(user_info, password) do
      {:ok, _params} -> {:ok, :valid_password}
      _ -> {:error, :valid_password}
    end
  end

  @spec check_password_user_and_password(username(), password(), :email | :username) ::
          {:error, :check_password_user_and_password, :email | :username}
          | {:ok, :check_password_with_username, :email | :username, Ecto.Schema.t()}
  def check_password_user_and_password(username, password, :username) do
    with {:ok, :find_user_with_username, user_info} <- find_user_with_username(username),
         {:ok, :chack_password_not_null} <- chack_password_not_null(user_info.password_hash),
         {:ok, :valid_password} <- valid_password(user_info, password) do

          {:ok, :check_password_with_username, :username, user_info}
    else
      _ ->
        {:error, :check_password_user_and_password, :username}
    end
  end

  def check_password_user_and_password(email, password, :email) do
    with {:ok, :find_user_with_email, user_info} <- find_user_with_email(email),
         {:ok, :chack_password_not_null} <- chack_password_not_null(user_info.password_hash),
         {:ok, :valid_password} <- valid_password(user_info, password) do

          {:ok, :check_password_with_username, :email, user_info}
    else
      _ ->
        {:error, :check_password_user_and_password, :email}
    end
  end


  def chack_password_not_null(pass) do
    if pass == nil, do: {:error, :chack_password_not_null}, else: {:ok, :chack_password_not_null}
  end
  def set_set_systematic_user_data(user_params, :direct) do
    Map.merge(%{"unconfirmed_email" => user_params["email"]}, MishkaAuth.Extra.strong_params(user_params, @register_params))
  end

  def set_set_systematic_user_data(user_params, :social) do
    Map.merge(%{"unconfirmed_email" => nil, "status" => "active"}, MishkaAuth.Extra.strong_params(user_params, @register_params))
  end
end
