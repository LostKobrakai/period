defmodule Generators do
  use ExUnitProperties

  @time_zones ["Etc/UTC"]

  def date do
    gen all year <- integer(1970..2050),
            month <- integer(1..12),
            day <- integer(1..31),
            match?({:ok, _}, Date.from_erl({year, month, day})) do
      Date.from_erl!({year, month, day})
    end
  end

  def time do
    gen all hour <- integer(0..23),
            minute <- integer(0..59),
            second <- integer(0..59) do
      Time.from_erl!({hour, minute, second})
    end
  end

  def naive_datetime do
    gen all date <- date(),
            time <- time() do
      {:ok, naive_datetime} = NaiveDateTime.new(date, time)
      naive_datetime
    end
  end

  def datetime(timezones \\ @time_zones) do
    gen all naive_datetime <- naive_datetime(),
            time_zone <- member_of(timezones) do
      DateTime.from_naive!(naive_datetime, time_zone)
    end
  end

  def period do
    gen all a <- naive_datetime(),
            b <- naive_datetime(),
            lb <- boolean(),
            ub <- boolean(),
            lb == ub || :eq != NaiveDateTime.compare(a, b) do
      {earlier, later} = sort_date(a, b)

      {:ok, period} = Period.new(later, earlier, lower_included: lb, upper_included: ub)

      period
    end
  end

  def sort_date(a, b) do
    if :gt == NaiveDateTime.compare(a, b) do
      {b, a}
    else
      {a, b}
    end
  end
end
