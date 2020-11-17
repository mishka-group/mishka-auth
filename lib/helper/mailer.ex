defmodule MishkaAuth.Helper.Mailer do
  def mailer do
    MishkaAuth.get_config_info(:mailer)
  end
end
