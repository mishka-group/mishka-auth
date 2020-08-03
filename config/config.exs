use Mix.Config


config :phoenix, :json_library, Jason
# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]


config :mishka_auth, MishkaAuth.Guardian,
issuer: "auth_service",
allowed_algos: ["ES512"],
secret_key: %{
  "alg" => "ES512",
  "crv" => "P-521",
  "d" => "AUNo6IoAsmLrY10nX1SJqL2HA3MTSeHfhyu63Vl8Ise1z7UCi_Al5gujHvRKoA9Gcs4qeBte5LMyb2OVjYyYQa2j",
  "kty" => "EC",
  "use" => "sig",
  "x" => "AY4DWiHNRiOJrxNiD8QXZD6tT8ZspCY4FbxqDD0Kqecgu3ww5MeoMZq16PcWtJ96z32prKvwAroOjHVrKtuFavHa",
  "y" => "AUNAQ2eDEelM2fMot8ACOdu5HrH0G5rrHiEyjQzwMQQxm2p79BAusIQQ0_GlI-Zm_zgXDHNhhaWokbSXHMSNapy9"
}

import_config "#{Mix.env()}.exs"
