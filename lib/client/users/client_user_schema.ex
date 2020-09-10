defmodule MishkaAuth.Client.Users.ClientUserSchema do
  use Ecto.Schema
  alias MishkaAuth.Helper.SanitizeStrategy


  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

   schema "users" do

     field :name, :string, size: 20, null: false
     field :lastname, :string, size: 20, null: true
     field :username, :string, size: 20, null: false
     field :email, :string, null: false
     field :password_hash, :string, null: true
     field :password, :string, virtual: true
     field :status, StatusEnum, null: false, default: :registered
     field :unconfirmed_email, :string, null: true

     has_many :identities, MishkaAuth.Client.Identity.ClientIdentitySchema,  foreign_key: :user_id
     timestamps()
   end

   @spec changeset(
           {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
           :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
         ) :: Ecto.Changeset.t()

   def changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:name, :lastname, :username, :email, :password_hash, :password, :status, :unconfirmed_email])
     |> validate_required([:name, :username, :email, :status], message: "can't be blank")
     |> validate_length(:name, min: 3, max: 20, message: "minimum 3 characters and maximum 20 characters")
     |> validate_length(:lastname, min: 3, max: 20, message: "minimum 3 characters and maximum 20 characters")
     |> validate_length(:password, min: 8, max: 100, message: "minimum 8 characters and maximum 100 characters")
     |> validate_length(:username, min: 3, max: 20, message: "minimum 3 characters and maximum 20 characters")
     |> validate_length(:email, min: 8, max: 50, message: "minimum 8 characters and maximum 50 characters")

     |> SanitizeStrategy.changeset_input_validation(MishkaAuth.get_config_info(:input_validation_status))



     |> unique_constraint(:unconfirmed_email, name: :index_on_users_verified_email, message: "this email has already been taken.")
     |> unique_constraint(:username, name: :index_on_users_username, message: "this username has already been taken.")
     |> unique_constraint(:email, name: :index_on_users_email, message: "this email has already been taken.")
     |> hash_password
   end

   @spec unconfirmed_email_changeset(
           {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
           :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
         ) :: Ecto.Changeset.t()

   def unconfirmed_email_changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:unconfirmed_email])
     |> validate_required([:unconfirmed_email], message: "Email can't be blank")
   end

   @spec change_password_changeset(
           {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
           :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
         ) :: Ecto.Changeset.t()

   def change_password_changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:password])
     |> validate_required([:password], message: "Password can't be blank")
     |> validate_length(:password, min: 8, max: 100, message: "minimum 8 characters and maximum 100 characters")
     |> hash_password
   end

   defp hash_password(changeset) do
     case changeset do
       %Ecto.Changeset{valid?: true, changes: %{password: password}} ->
         put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
       _ -> changeset
     end
   end
   # Bcrypt.verify_pass "ORIGINAL PASS", HASHPASS

end
