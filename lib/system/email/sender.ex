defmodule MishkaAuth.Email.Sender do
  import Bamboo.Email
  use Timex

  @spec account_email(:reset_password | :verify_email, map(), String.t()) ::
          Bamboo.Email.t()
  def account_email(type, info, country) do
    your_country = Timex.now("#{country}")
    new_email(
      to: "#{info.email}",
      from: "system@khatoghalam.com",
      subject: "#{info.subject}",
      headers: %{
        "Return-Path" => "#{info.email}",
        "Subject" => "#{info.subject}",
        "Date" => "#{Timex.format!(your_country, "{WDshort}, {D} {Mshort} {YYYY} {h24}:{0m}:{0s} {Z}")}",
        "message-id" => "<#{:base64.encode(:crypto.strong_rand_bytes(64))}#{MishkaAuth.get_config_info(:email_name)}>"
      },
      text_body: email_type(type, info).text,
      html_body: email_type(type, info).html
    )
  end


  @spec email_type(:reset_password | :verify_email, map()) :: any
  def email_type(:reset_password, info) do
    config = MishkaAuth.get_config_info(:reset_password_email)
    apply(config.module, config.function, [info])
  end

  def email_type(:verify_email, info) do
    config = MishkaAuth.get_config_info(:verify_email)
    apply(config.module, config.function, [info])
  end
end
