defmodule PeriodTest do
  use ExUnit.Case
  use ExUnitProperties
  import Generators
  doctest Period

  describe "new/3" do

    property "it does naivify both dates if one of the dates is naive" do
      check all a <- datetime(),
                b <- naive_datetime(),
                switch <- boolean(),
                :eq != NaiveDateTime.compare(a, b) do
        [lower, upper] =
          if switch do
            [a, b]
          else
            [b, a]
          end

        assert {:ok, %{lower: %NaiveDateTime{}, upper: %NaiveDateTime{}}} = Period.new(lower, upper)
      end
    end

    property "it keep a datetime duo" do
      check all lower <- datetime(),
                upper <- datetime(),
                :eq != DateTime.compare(lower, upper) do
        assert {:ok, %{lower: %DateTime{}, upper: %DateTime{}}} = Period.new(lower, upper)
      end
    end

    property "it does switch dates if the order doesn't work and strict mode is not enabled" do
      check all a <- one_of([datetime(["Etc/UTC"]), naive_datetime()]),
                b <- one_of([datetime(["Etc/UTC"]), naive_datetime()]),
                :eq != NaiveDateTime.compare(a, b) do
        {earlier, later} = sort_date(a, b)
        {:ok, %{lower: returned_lower, upper: returned_upper}} = Period.new(later, earlier)

        assert :eq == NaiveDateTime.compare(earlier, returned_lower)
        assert :eq == NaiveDateTime.compare(later, returned_upper)
      end
    end

    property "it does error for incorrectly ordered dates in strict mode" do
      check all a <- one_of([datetime(), naive_datetime()]),
                b <- one_of([datetime(), naive_datetime()]) do
        {earlier, later} = sort_date(a, b)
        {:error, _} = Period.new(later, earlier, strict: true)
      end
    end

    test "it does compare boundries with timezones in mind if two datetimes are supplied" do
      later = DateTime.utc_now()
      earlier = %{later | utc_offset: 3600, std_offset: 0, time_zone: "Europe/Warsaw",  zone_abbr: "CET"}

      {:ok, %{lower: ^earlier, upper: ^later}} = Period.new(earlier, later)
    end

    property "it does return an error for equal dates if one boundry is excluded and the other included" do
      check all date <- one_of([datetime(), naive_datetime()]) do
        assert {:error, _} = Period.new(date, date, lower_included: true, upper_included: false)
        assert {:error, _} = Period.new(date, date, lower_included: false, upper_included: true)
        assert {:ok, %Period{}} = Period.new(date, date, lower_included: true, upper_included: true)
        assert {:ok, %Period{}} = Period.new(date, date, lower_included: false, upper_included: false)
      end
    end

  end

  describe "new!/3" do

    property "it does raise for equal dates if one boundry is excluded and the other included" do
      check all date <- one_of([datetime(), naive_datetime()]) do
        assert %Period{} = Period.new!(date, date, lower_included: true, upper_included: true)
        assert %Period{} = Period.new!(date, date, lower_included: false, upper_included: false)

        assert_raise ArgumentError, fn ->
          Period.new!(date, date, lower_included: true, upper_included: false)
        end

        assert_raise ArgumentError, fn ->
          Period.new!(date, date, lower_included: false, upper_included: true)
        end
      end
    end

    property "it does error for incorrectly ordered dates in strict mode" do
      check all a <- one_of([datetime(), naive_datetime()]),
                b <- one_of([datetime(), naive_datetime()]) do
        {earlier, later} = sort_date(a, b)

        assert_raise ArgumentError, fn ->
          Period.new!(later, earlier)
        end
      end
    end

  end

  property "it does return it's correct start date and boundry setting" do
    check all a <- naive_datetime(),
              b <- naive_datetime(),
              lb <- boolean(),
              ub <- boolean(),
              lb == ub || :eq != NaiveDateTime.compare(a, b) do
      {earlier, later} = sort_date(a, b)

      {:ok, period} = Period.new(later, earlier, lower_included: lb, upper_included: ub)

      assert {^earlier, ^lb} = Period.get_lower_boundry(period)
      assert {^later, ^ub} = Period.get_upper_boundry(period)
    end
  end

  # property "relationship solver" do
  #   check all a <- period(),
  #             b <- period() do
  #     IO.inspect {Period.Relationship.period_relationship(a, b), a, b}
  #   end
  # end
end
