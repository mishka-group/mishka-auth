defmodule MishkaAuth.Client.Users.ClientUserLimiter do

  alias MishkaAuth.RedisClient, as: Redis

  #### change redis time just to limit brut force ####


  # strategies = %{
  #   :register_limiter,
  #   :login_limiter,
  #   :reset_password_limiter,
  #   :verify_email_limiter
  # }

  @spec is_data_limited?(any, any, any) ::
          {:error, :is_data_limited? | :limiter, :inactive | [{:number, integer}, ...]}
          | {:ok, :is_data_limited?, any, any, any}
  def is_data_limited?(strategy, email, user_ip) do
    case MishkaAuth.get_config_info(:limiter) do
      true ->
        limiter(strategy, email, user_ip)
      _ ->
        {:error, :limiter, :inactive}
    end

  end


  # [:register_limiter]
  @spec limiter(atom, any, any) ::
          {:error, :is_data_limited?, [{:number, integer}, ...]}
          | {:ok, :is_data_limited?, any, any, any}
  def limiter(:register_limiter = strategy, last_email, user_ip) do
    Redis.get_data_of_singel_id(Atom.to_string(strategy), user_ip)
    |> is_there_a_limiter_record?(strategy, last_email, user_ip)
    |> limiter_condition()
  end

  # [:login_limiter, :reset_password_limiter, :verify_email]
  def limiter(strategy, email, user_ip) do
    Redis.get_data_of_singel_id(Atom.to_string(strategy), email)
    |> is_there_a_limiter_record?(strategy, email, user_ip)
    |> limiter_condition()
  end


  @spec is_there_a_limiter_record?({:error, atom(), any} | {:ok, any, any}, any, any, any) ::
          {:ok, :is_there_a_limiter_record?, any, any, atom}
          | {:error, :is_there_a_limiter_record?, any, any, any, any}
  def is_there_a_limiter_record?({:ok, _atom, record}, limiter_strategy, email, user_ip) do
    {:error, :is_there_a_limiter_record?, email, user_ip, limiter_strategy, record}
  end

  def is_there_a_limiter_record?({:error, _atom, _msg}, :register_limiter, last_email, user_ip) do
    add_to_redis(:register_limiter, last_email, 1, user_ip, 300) #5 min
    {:ok, :is_there_a_limiter_record?, last_email, user_ip, :register_limiter}
  end

  def is_there_a_limiter_record?({:error, _atom, _msg}, limiter_strategy, email, user_ip) do
    add_to_redis(limiter_strategy, email, 1, user_ip,  300) #5 min
    {:ok, :is_there_a_limiter_record?, email, user_ip, limiter_strategy}
  end

  @spec limiter_condition(
          {:ok, :is_there_a_limiter_record?, String.t(), String.t(), any()}
          | {:error, :is_there_a_limiter_record?, String.t(), String.t(),
             :login_limiter | :register_limiter | :reset_password_limiter | :verify_email_limiter,
             nil | maybe_improper_list | map}
        ) ::
          {:error, :is_data_limited?, [{:number, integer}, ...]}
          | {:ok, :is_data_limited?, any, any, any}
  def limiter_condition({:ok, :is_there_a_limiter_record?, email, user_ip, limiter_strategy}) do
    {:ok, :is_data_limited?, email, user_ip, limiter_strategy}
  end

  def limiter_condition({:error, :is_there_a_limiter_record?, email, user_ip, limiter_strategy, record}) do
    check_limiter_number_with_time(email, user_ip, limiter_strategy, record)
  end

  @spec check_limiter_number_with_time(
          String.t(),
          String.t(),
          :login_limiter | :register_limiter | :reset_password_limiter | :verify_email_limiter,
          nil | maybe_improper_list | map
        ) ::
          {:error, :is_data_limited?, [{:number, integer}, ...]}
          | {:ok, :is_data_limited?, any, any, :reset_password_limiter}
  def check_limiter_number_with_time(email, user_ip, :reset_password_limiter, record) do
    cond do
      String.to_integer(record["number"]) == 2 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 2 ->
        add_to_redis(:reset_password_limiter, email, 3, user_ip, 300) #5 min
        {:error, :is_data_limited?, number: 3}

      String.to_integer(record["number"]) == 3 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 10 ->
        add_to_redis(:reset_password_limiter, email, 4, user_ip, 600)
        {:error, :is_data_limited?, number: 4}

      String.to_integer(record["number"]) == 4 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 1440 ->
        add_to_redis(:reset_password_limiter, email, 5, user_ip, 86400)
        {:error, :is_data_limited?, number: 5}

      String.to_integer(record["number"]) >= 4 ->
        add_to_redis(:reset_password_limiter, email, String.to_integer(record["number"]) + 1, user_ip, 86400)
        {:error, :is_data_limited?, number: String.to_integer(record["number"]) + 1}

      true ->
        IO.inspect String.to_integer(record["number"])
        IO.inspect convert_string_to_utc(record["update_time"])
        add_to_redis(:reset_password_limiter, email, 2, user_ip, 300)
        {:ok, :is_data_limited?, email, user_ip, :reset_password_limiter}
    end
  end

  def check_limiter_number_with_time(email, user_ip, :login_limiter, record) do
    cond do
      String.to_integer(record["number"]) == 5 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 3 ->
        add_to_redis(:reset_password_limiter, email, 6, user_ip, 300)
        {:error, :is_data_limited?, number: 6}

      String.to_integer(record["number"]) == 6 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 10 ->
        add_to_redis(:reset_password_limiter, email, 7, user_ip, 600)
        {:error, :is_data_limited?, number: 7}

      String.to_integer(record["number"]) == 7 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 1440 ->
        add_to_redis(:reset_password_limiter, email, 8, user_ip, 86400)
        {:error, :is_data_limited?, number: 8}

      String.to_integer(record["number"]) >= 8 ->
        add_to_redis(:reset_password_limiter, email, String.to_integer(record["number"]) + 1, user_ip, 86400)
        {:error, :is_data_limited?, number: String.to_integer(record["number"]) + 1}

      true ->
        add_to_redis(:reset_password_limiter, email, String.to_integer(record["number"]) + 1, user_ip, 300)
        {:ok, :is_data_limited?, email, user_ip, :reset_password_limiter}
    end
  end

  def check_limiter_number_with_time(email, user_ip, :register_limiter, record) do
    cond do
      String.to_integer(record["number"]) == 2 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 2 ->
        add_to_redis(:reset_password_limiter, email, 3, user_ip, 300)
        {:error, :is_data_limited?, number: 3}

      String.to_integer(record["number"]) == 3 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 10 ->
        add_to_redis(:reset_password_limiter, email, 4, user_ip, 600)
        {:error, :is_data_limited?, number: 4}

      String.to_integer(record["number"]) == 4 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 1440 ->
        add_to_redis(:reset_password_limiter, email, 5, user_ip, 86400)
        {:error, :is_data_limited?, number: 5}

      String.to_integer(record["number"]) >= 4 ->
        add_to_redis(:reset_password_limiter, email, String.to_integer(record["number"]) + 1, user_ip, 86400)
        {:error, :is_data_limited?, number: String.to_integer(record["number"]) + 1}

      true ->
        add_to_redis(:reset_password_limiter, email, 2, user_ip, 300)
        {:ok, :is_data_limited?, email, user_ip, :reset_password_limiter}
    end
  end

  def check_limiter_number_with_time(email, user_ip, :verify_email_limiter, record) do
    cond do
      String.to_integer(record["number"]) == 2 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 2 ->
        add_to_redis(:reset_password_limiter, email, 3, user_ip, 300)
        {:error, :is_data_limited?, number: 3}

      String.to_integer(record["number"]) == 3 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 30 ->
        add_to_redis(:reset_password_limiter, email, 4, user_ip, 1800)
        {:error, :is_data_limited?, number: 4}

      String.to_integer(record["number"]) == 4 and Timex.diff(Timex.now, convert_string_to_utc(record["update_time"]), :minute) <= 1440 ->
        add_to_redis(:reset_password_limiter, email, 5, user_ip, 86400)
        {:error, :is_data_limited?, number: 5}

      String.to_integer(record["number"]) >= 4 ->
        add_to_redis(:reset_password_limiter, email, String.to_integer(record["number"]) + 1, user_ip, 86400)
        {:error, :is_data_limited?, number: String.to_integer(record["number"]) + 1}

      true ->
        add_to_redis(:reset_password_limiter, email, 2, user_ip, 300)
        {:ok, :is_data_limited?, email, user_ip, :reset_password_limiter}
    end
  end

  @spec add_to_redis(atom, String.t(), integer(), String.t(), integer()) :: {:ok, :insert_or_update_into_redis}
  def add_to_redis(:register_limiter, email, number, user_ip, time) do
    Redis.insert_or_update_into_redis(Atom.to_string(:register_limiter), user_ip, %{
      number: number, email: email, user_ip: user_ip, update_time: Timex.now
    }, time)
  end

  def add_to_redis(strategy, email, number, user_ip, time) do
    Redis.insert_or_update_into_redis(Atom.to_string(strategy), email, %{
      number: number, email: email, user_ip: user_ip, update_time: Timex.now
    }, time)
  end

  @spec convert_string_to_utc(binary) :: %{
          :__struct__ => DateTime | NaiveDateTime,
          :calendar => atom,
          :day => pos_integer,
          :hour => non_neg_integer,
          :microsecond => {non_neg_integer, non_neg_integer},
          :minute => non_neg_integer,
          :month => pos_integer,
          :second => non_neg_integer,
          :year => integer,
          optional(:std_offset) => integer,
          optional(:time_zone) => binary,
          optional(:utc_offset) => integer,
          optional(:zone_abbr) => binary
        }
  def convert_string_to_utc(time) do
    Timex.parse!(time, "{ISO:Extended}")
  end
end
