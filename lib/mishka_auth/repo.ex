defmodule MishkaAuth.Repo do
  use Ecto.Repo,
    otp_app: :mishka_auth,
    adapter: Ecto.Adapters.Postgres
end
