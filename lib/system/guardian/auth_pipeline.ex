defmodule MishkaAuth.AuthPipeline do
	@claims %{typ: "access"}

  use Guardian.Plug.Pipeline, otp_app: :bank_error, module: MishkaAuth.Guardian, error_handler: MishkaAuth.AuthErrorHandler

  # plug Guardian.Plug.VerifySession, claims: @claims
  plug Guardian.Plug.VerifyHeader, claims: @claims, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true


  # json VerifyHeader
  # plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  # plug Guardian.Plug.LoadResource, ensure: true, allow_blank: true
end
