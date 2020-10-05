defmodule MishkaAuth.Helper.Captcha.Google do
  @type remoteip() :: String.t()
  @type response() :: String.t()
  @type secret() :: String.t()
  @type provider() :: atom()

  # Google doc
  # <script src="https://www.google.com/recaptcha/api.js"></script>

  # <script>
  #   function onSubmit(token) {
  #     document.getElementById("demo-form").submit();
  #   }
  # </script>

  # <button
  #   class="g-recaptcha"
  #   data-sitekey="reCAPTCHA_site_key"
  #   data-callback='onSubmit'
  #   data-action='submit'>Submit
  # </button>

  # "success" => true
  # %{
  #   "action" => "submit",
  #   "challenge_ts" => "2020-10-05T14:44:34Z",
  #   "hostname" => "localhost",
  #   "score" => 0.9,
  #   "success" => true
  # }

  # "success" => false
  # %{
  #   "error-codes" => ["invalid-input-response"],
  #   "success" => false}
  # }

  @google_link "https://www.google.com/recaptcha/api/siteverify"


  @spec verify(response(), remoteip(), secret()) ::
          {:error, :google_response, :unexpected_error_or_not_active}
          | {:error, :captcha_verify, :google, any}
          | {:ok, :captcha_verify, :google, map}

  def verify(response, remoteip, secret) do
    google_sender(response, remoteip, secret)
    |> google_response
    |> google_converter
  end

  @spec google_sender(response(), remoteip(), secret()) ::
          {:error, HTTPoison.Error.t()}
          | {:ok,
             %{
               :__struct__ => HTTPoison.AsyncResponse | HTTPoison.Response,
               optional(:body) => any,
               optional(:headers) => [any],
               optional(:id) => reference,
               optional(:request) => HTTPoison.Request.t(),
               optional(:request_url) => any,
               optional(:status_code) => integer
             }}

  def google_sender(response, remoteip, secret) do
    body = %{
      "secret" => secret,
      "response" => response,
      "remoteip" => "#{remoteip}"
    }
    |> URI.encode_query()

    HTTPoison.post(
      "#{@google_link}",
        body,
        [
          {"Content-Type", "application/x-www-form-urlencoded"},
          {"Accept", "text/html"}
        ],
       [timeout: 50_000, recv_timeout: 50_000]
    )
  end

  @spec google_response(any) :: {:error, :google_response, any} | {:ok, :google_response, map}

  def google_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, :google_response, Jason.decode!(body)}

      {:ok, %HTTPoison.Response{status_code: 401}} ->
        {:error, :google_response, :no_access}

      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, :google_response, :bad_data}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, :google_response, reason}

      _ ->
        {:error, :google_response, :unexpected_error}
    end
  end

  @spec google_converter(any) ::
          {:error, :google_response, :unexpected_error_or_not_active}
          | {:error, :captcha_verify, :google, any}
          | {:ok, :captcha_verify, :google, map}

  def google_converter({:ok, :google_response, %{"error-codes" => reason, "success" => false}}) do
    {:error, :captcha_verify, :google, reason}
  end

  def google_converter({:ok, :google_response, %{"success" => true} = google_params}) do
    {:ok, :captcha_verify, :google, google_params}
  end

  def google_converter({:error, :google_response, reason}) do
    {:error, :captcha_verify, :google, reason}
  end

  def google_converter(_params) do
    {:error, :google_response, :unexpected_error_or_not_active}
  end
end
