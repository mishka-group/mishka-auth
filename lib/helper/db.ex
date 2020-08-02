defmodule MishkaAuth.Helper.Db do

  def repo do
    MishkaAuth.get_config_info(:repo)
  end
  
end
