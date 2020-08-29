defmodule MishkaAuth.Helper.Db do

  @spec repo :: any
  def repo do
    MishkaAuth.get_config_info(:repo)
  end

end
