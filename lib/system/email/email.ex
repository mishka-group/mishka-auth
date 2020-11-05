defmodule MishkaAuth.Email.Sender do
  import Bamboo.Email
  use Timex
  use Phoenix.HTML

  @site_link MishkaAuth.get_config_info(:site_link)

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
        "message-id" => "<#{:base64.encode(:crypto.strong_rand_bytes(64))}@trangell.com>"
      },
      text_body: email_type(type, info).text,
      html_body: email_type(type, info).html
    )
  end


  def email_type("reset_password", info) do
    %{
      text: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
      html: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
    }
  end
end
