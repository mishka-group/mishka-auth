defmodule MishkaAuth.Client.Users.ClientUserSchema do
  use Ecto.Schema


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

   def changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:name, :lastname, :username, :email, :password_hash, :password, :status, :unconfirmed_email])
     |> validate_required([:name, :username, :email, :status], message: "فیلد مذکور نمی تواند خالی باشد.")
     |> validate_length(:name, min: 3, max: 20, message: "نام شما باید بین ۳ الی ۲۰ کاراکتر باشد.")
     |> validate_length(:lastname, min: 3, max: 20, message: "نام خانوادگی شما باید بین ۳ الی ۲۰ کارکتر باشد.")
     |> validate_length(:password, min: 8, max: 100, message: "پسورد شما باید حداقل ۸ کاراکتر باشد و حداکثر ۲۰۰ لطفا پسورد مناسبی انتخاب کنید.")
     |> validate_length(:username, min: 3, max: 20, message: "نام کاربری شما باید بین ۳ الی ۲۰ کارکتر باشد.")
     |> validate_length(:email, min: 8, max: 50, message: "تعداد کارکتر های ایمیل باید بین ۸ تا ۵۰ عدد باشد.")
     |> validate_format(:email, ~r/@/, message: "فرمت ایمیل درست نمی باشد.")
     |> unique_constraint(:unconfirmed_email, name: :index_on_users_verified_email, message: "ایمیل درخواست تمدید از قبل وجود دارد.")
     |> unique_constraint(:username, name: :index_on_users_username, message: "نام کاربری وارد شده از قبل وجود دارد.")
     |> unique_constraint(:email, name: :index_on_users_email, message: "ایمیل وارد شده از قبل وجود دارد.")
     |> hash_password
   end

   def unconfirmed_email_changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:unconfirmed_email])
     |> validate_required([:unconfirmed_email], message: "متاسفانه ایمیل فعال سازی ارسال نگردیده است.")
   end

   def change_password_changeset(struct, params \\ %{}) do
     struct
     |> cast(params, [:password])
     |> validate_required([:password], message: "متاسفانه پارامتر پسورد وارد نشده است.")
     |> validate_length(:password, min: 8, max: 100, message: "پسورد شما باید حداقل ۸ کاراکتر باشد و حداکثر ۲۰۰ لطفا پسورد مناسبی انتخاب کنید.")
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
