defmodule MishkaAuth.Helper.Captcha do
  @type remoteip() :: String.t()
  @type response() :: String.t()
  @type provider() :: atom()

  alias MishkaAuth.Helper.Captcha.Google


  @spec verify(provider(), %{remoteip: remoteip(), response: response()}) ::
          {:error, :google_response, :unexpected_error_or_not_active}
          | {:error, :captcha_verify, :google, any}
          | {:ok, :captcha_verify, :google, map}

  def verify(:google, google_params) do
    case MishkaAuth.get_config_info(:captcha) do
      {true, :google} ->
        secret = MishkaAuth.get_config_info(:google_re_captcha_secret)
        Google.verify(google_params.response, google_params.remoteip, secret)
      _ ->
        Google.google_converter(:not_active)
    end

  end
end
