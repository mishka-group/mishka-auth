defmodule MishkaAuth.RedisClient do
    @moduledoc """
      You will be able to handle Redis with this module, it has CRUD functions to use Redis,
      it should be noted it does your work with easy way
    """

    @spec insert_or_update_into_redis(binary, binary, map(), any) ::
            {:ok, :insert_or_update_into_redis}
    @doc """
      with this function you can connect to redis file for example `redis-server redis.conf`,
      its password was put like hardcode. you should change it in future.

    # def connect_to_redis do
    #   Redix.pipeline(:redix, [["AUTH","9GXXnt2qtqLv7p2fYvBWE1kAWif1OXRMHOL/7IoSvCLBF5v0+eCwasYXGeeoxaT6KAQE8HB0jCwcoz+6"]]) # will be changed
    # end

      this function can be used ether insering data to redis or update data, the type of expire_time is seconds.
      the params type is Map - tuple.
    """
    def insert_or_update_into_redis(table_name, record_id, params, expire_time) do

        :redix |>
        Redix.pipeline([
          List.flatten(
            [
              "HMSET",
              # String.to_charlist(table_name <> record_id)
              "#{table_name}#{record_id}"
            ], MishkaAuth.Extra.map_to_single_list_with_string_key(params)
          ),
          [
            "EXPIRE",
            table_name <> record_id,
            expire_time
          ]
        ])
        {:ok, :insert_or_update_into_redis}
    end

    @spec get_all_fields_of_record_redis(binary, binary) :: [
            nil
            | binary
            | [nil | binary | [any] | integer | Redix.Error.t()]
            | integer
            | Redix.Error.t()
          ]
    @doc """
      show all fields of redis record
    """
    def get_all_fields_of_record_redis(table_name, record_id) do

      :redix
      |> Redix.pipeline!([["HGETALL",table_name <> record_id]])
    end

    @spec get_singel_field_record_of_redis(any, any, any) :: [
            nil
            | binary
            | [nil | binary | [any] | integer | Redix.Error.t()]
            | integer
            | Redix.Error.t()
          ]
    @doc """
      show singel fields of redis record
    """
    def get_singel_field_record_of_redis(table_name, record_id, field_name) do

      :redix
      |> Redix.pipeline!([["HGET","#{table_name}#{record_id}", field_name]])
    end

    @spec delete_record_of_redis(binary, binary) ::
            {:error, :get_all_fields_of_record_redis, <<_::256>>}
            | {:ok, :delete_record_of_redis, <<_::168>>}
    @doc """
      delete redis record
    """
    def delete_record_of_redis(table_name, record_id) do
      with {:ok, :get_all_fields_of_record_redis, record} <- convert_output_of_get_all_fields_of_record_redis(get_all_fields_of_record_redis(table_name, record_id)) do


            :redix
            |> Redix.pipeline([["HDEL", table_name <> record_id] ++ record])
            {:ok, :delete_record_of_redis, "The record is deleted"}
      else
        n ->  n
      end
    end

    @spec convert_output_of_get_all_fields_of_record_redis(maybe_improper_list) ::
            {:error, :get_all_fields_of_record_redis, <<_::256>>}
            | {:ok, :get_all_fields_of_record_redis, any}

    def convert_output_of_get_all_fields_of_record_redis(params) do
      case params do
        [[]] -> {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"}
        [] -> {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"}
        [nil] -> {:error, :get_all_fields_of_record_redis, "The data concerned doesn't exist"}
        n ->
          [record | _] = n
          {:ok, :get_all_fields_of_record_redis, record}
      end
    end

    @spec delete_field_of_record_redis(binary, binary, any) ::
            {:error,
             atom
             | %{
                 :__exception__ => any,
                 :__struct__ => Redix.ConnectionError | Redix.Error,
                 optional(:message) => binary,
                 optional(:reason) => atom
               }}
            | {:ok,
               :delete_field_of_record_redis
               | [
                   nil
                   | binary
                   | [nil | binary | [any] | integer | map]
                   | integer
                   | Redix.Error.t()
                 ]}
            | {:error, :delete_field_of_record_redis | :get_all_fields_of_record_redis,
               <<_::256>>}

    @doc """
      delete singel field of redis record
    """
    def delete_field_of_record_redis(table_name, record_id, field_name) do

      with {:ok, :get_all_fields_of_record_redis, _record} <- convert_output_of_get_all_fields_of_record_redis(get_all_fields_of_record_redis(table_name, record_id)),
           {:ok, [1]} <- Redix.pipeline(:redix, [["HDEL", table_name <> record_id, field_name]]) do

            {:ok, :delete_field_of_record_redis}
      else
        {:ok, [0]} -> {:error, :delete_field_of_record_redis, "The field you need doesn't exist"}
        n -> n
      end
    end

    @spec get_expire_time_of_redis(binary, binary) ::
            {:error, :get_expire_time_error_handler, <<_::256>>}
            | {:ok, :get_expire_time,
               nil | binary | [nil | binary | [any] | integer | map] | integer | Redix.Error.t()}
    @doc """
      get expire time of singel record
    """
    def get_expire_time_of_redis(table_name, record_id) do
      with {:ok, :get_expire_time_error_handler, expire_time} <- get_expire_time_error_handler(:redix, table_name, record_id) do

          {:ok, :get_expire_time, expire_time}
      else
        n -> n
      end
    end

    defp get_expire_time_error_handler(conn, table_name, record_id) do
      case Redix.pipeline(conn, [["TTL",table_name <> record_id]]) do
        {:ok, [-2]} ->
          {:error, :get_expire_time_error_handler, "The data concerned doesn't exist"}

        {:ok, [expire_time]} ->
          {:ok, :get_expire_time_error_handler, expire_time}

        _ ->
        {:error, :get_expire_time_error_handler, "The data concerned doesn't exist"}
      end
    end

    @spec update_expire_time_of_redis(binary, binary, any) ::
            {:error, :update_expire_time_of_error_handler, <<_::256>>}
            | {:ok, :update_expire_time_of_redis, <<_::240>>}
    @doc """
      get expire time of singel record
    """
    def update_expire_time_of_redis(table_name, record_id, expire_time) do
      with {:ok, :update_expire_time_of_error_handler, msg} <- update_expire_time_of_error_handler(:redix, table_name, record_id, expire_time) do

          {:ok, :update_expire_time_of_redis, msg}
      else
        n -> n
      end
    end

    defp update_expire_time_of_error_handler(conn, table_name, record_id, expire_time) do
      case Redix.pipeline(conn, [["EXPIRE",table_name <> record_id, expire_time]]) do
        {:ok, [0]} ->
          {:error, :update_expire_time_of_error_handler, "The data concerned doesn't exist"}

        {:ok, [1]} ->
          {:ok, :update_expire_time_of_error_handler, "The data concerned was updated"}

        _ ->
        {:error, :update_expire_time_of_error_handler, "The data concerned doesn't exist"}
      end
    end



    @spec get_data_of_singel_id(binary, binary) ::
            {:error, :get_all_fields_of_record_redis, <<_::256>>}
            | {:ok, :get_data_of_singel_id, map}

    def get_data_of_singel_id(table_name, record_id) do
      data = get_all_fields_of_record_redis(table_name, record_id)
      |> convert_output_of_get_all_fields_of_record_redis

      case data do
        {:ok, :get_all_fields_of_record_redis, record} ->
          {:ok, :get_data_of_singel_id, MishkaAuth.Extra.list_to_map(record)}
        error -> error
      end
    end
end
