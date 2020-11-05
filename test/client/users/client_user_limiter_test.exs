defmodule MishkaAuthTest.Client.ClientUserLimiterTest do
  use ExUnit.Case
  use MishkaAuthWeb.ConnCase


  alias MishkaAuth.Client.Users.ClientUserLimiter, as: Limiter
  alias MishkaAuth.RedisClient

  # [:register_limiter] # [:login_limiter, :reset_password_limiter, :verify_email]

  describe "Happy | client User Limiter (▰˘◡˘▰)" do
    test "is data limited?" do
      {:ok, :is_data_limited?, _email, _user_ip, :reset_password_limiter} = assert Limiter.is_data_limited?(:reset_password_limiter, "info@trangell.com", "1.1.1.1")

      RedisClient.delete_record_of_redis("reset_password_limiter", "info@trangell.com")
    end
  end




  describe "UnHappy | client User Limiter ಠ╭╮ಠ" do
    test "is data limited?" do
      Limiter.add_to_redis(:reset_password_limiter, "e@e.com", 2, "1.1.1.1", 300)

      {:error, :is_data_limited?, number: 3} = assert Limiter.is_data_limited?(:reset_password_limiter, "e@e.com", "1.1.1.1")
    end
  end
end
