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

   def changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:identity_provider, :uid, :token, :user_id])
     |> validate_required([:identity_provider, :user_id], message: "فیلد مذکور نمی تواند خالی باشد.")
     |> foreign_key_constraint(:user_id, message: "امکان حذف وجود ندارد. دلیل این موضوع وابستگی بین این جدول با دیگر جداول می باشد")
     |> unique_constraint(:uid, name: :uniq_index_on_identities_uid_and_identity_provider, message: "این حساب کاربری از قبل وجود دارد.")
     |> unique_constraint(:identity_provider, name: :uniq_index_on_identities_user_id_and_identity_provider, message: "این حساب کاربری از قبل وجود دارد.")
   end

end
