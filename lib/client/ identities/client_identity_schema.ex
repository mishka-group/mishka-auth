defmodule MishkaAuth.Client.Identity.ClientIdentitySchema do
  use Ecto.Schema
  import Ecto.Changeset
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

   schema "identities" do

     field :identity_provider, IdentityProviderEnum, null: false
     field :uid, :string, null: true
     field :token, :string, null: true

     belongs_to :users, MishkaAuth.Client.Users.ClientUserSchema, foreign_key: :user_id, type: :binary_id
     timestamps()
   end

   @spec changeset(
           {map, map} | %{:__struct__ => atom | %{__changeset__: map}, optional(atom) => any},
           :invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}
         ) :: Ecto.Changeset.t()

   def changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:identity_provider, :uid, :token, :user_id])
     |> validate_required([:identity_provider, :user_id], message: "can't be blank")
     |> foreign_key_constraint(:user_id, message: "this username has already been taken or you can't delete it because there is a dependency")
     |> unique_constraint(:uid, name: :uniq_index_on_identities_uid_and_identity_provider, message: "this account has already been taken.")
     |> unique_constraint(:identity_provider, name: :uniq_index_on_identities_user_id_and_identity_provider, message: "this account has already been taken.")
   end

end
