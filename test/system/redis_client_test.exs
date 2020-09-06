defmodule MishkaAuthTest.System.RedisClientTest do
  use ExUnit.Case
  alias MishkaAuth.RedisClient
  use MishkaAuthWeb.ConnCase


  describe "Happy | System Extra (▰˘◡˘▰)" do
    test "insert or update into redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)
    end

    test "get_all_fields_of_record_redis(table_name, record_id)" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      [["test", "test"]] = assert RedisClient.get_all_fields_of_record_redis("test", "test")
    end

    test "get singel field record of redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)
      ["test"] = assert RedisClient.get_singel_field_record_of_redis("test", "test", "test")
    end

    test "delete record of redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      {:ok, :delete_record_of_redis, "The record is deleted"} = assert RedisClient.delete_record_of_redis("test", "test")
    end

    test "convert output of get all fields of record redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)


      {:ok, :get_all_fields_of_record_redis, _record} = assert RedisClient.convert_output_of_get_all_fields_of_record_redis(["test", "test"])
    end

    test "delete field of record redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      {:ok, :delete_field_of_record_redis} = assert RedisClient.delete_field_of_record_redis("test", "test", "test")
    end

    test "get expire time of redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      {:ok, :get_expire_time, 2000} = assert RedisClient.get_expire_time_of_redis("test", "test")
    end

    test "update expire time of redis" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      {:ok, :update_expire_time_of_redis, _msg} = assert RedisClient.update_expire_time_of_redis("test", "test", 300)

      {:ok, :get_expire_time, 300} = assert RedisClient.get_expire_time_of_redis("test", "test")

    end

    test "get data of singel id" do
      {:ok, :insert_or_update_into_redis} = assert RedisClient.insert_or_update_into_redis("test", "test", %{test: "test"}, 2000)

      {:ok, :get_data_of_singel_id, _data} = assert RedisClient.get_data_of_singel_id("test", "test")
    end
  end






  describe "UnHappy | System Extra ಠ╭╮ಠ" do
    test "convert output of get all fields of record redis" do
      {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"} = assert RedisClient.convert_output_of_get_all_fields_of_record_redis([])
    end

  end
end
