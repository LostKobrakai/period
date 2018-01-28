defmodule PeriodTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest Period

  describe "new/3" do
    property "it can accept any positive timestamps in correct order" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = a,
                upper = a + b do
        assert {:ok, %Period{}} = Period.new(lower, upper)
      end
    end

    property "it can accept any positive timestamps (even the same) for equal boundry setup" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = min(a, b),
                upper = max(a, b) do
        both_included = [lower_state: :included, upper_state: :included]
        assert {:ok, %Period{}} = Period.new(lower, upper, both_included)

        both_excluded = [lower_state: :excluded, upper_state: :excluded]
        assert {:ok, %Period{}} = Period.new(lower, upper, both_excluded)
      end
    end

    property "it does return an error for equal dates if one boundry is excluded and the other included" do
      check all timestamp <- positive_integer() do
        lower_state = [lower_state: :included, upper_state: :excluded]
        assert {:error, _} = Period.new(timestamp, timestamp, lower_state)

        upper_state = [lower_state: :excluded, upper_state: :included]
        assert {:error, _} = Period.new(timestamp, timestamp, upper_state)
      end
    end
  end

  describe "new!/3" do
    property "it can accept any positive timestamps in correct order" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = a,
                upper = a + b do
        assert %Period{} = Period.new!(lower, upper)
      end
    end

    property "it can accept any positive timestamps (even the same) for equal boundry setup" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = min(a, b),
                upper = max(a, b) do
        both_included = [lower_state: :included, upper_state: :included]
        assert %Period{} = Period.new!(lower, upper, both_included)

        both_excluded = [lower_state: :excluded, upper_state: :excluded]
        assert %Period{} = Period.new!(lower, upper, both_excluded)
      end
    end

    property "it does raise for equal dates if one boundry is excluded and the other included" do
      check all timestamp <- positive_integer() do
        lower_state = [lower_state: :included, upper_state: :excluded]

        assert_raise ArgumentError, fn ->
          Period.new!(timestamp, timestamp, lower_state)
        end

        upper_state = [lower_state: :excluded, upper_state: :included]

        assert_raise ArgumentError, fn ->
          Period.new!(timestamp, timestamp, upper_state)
        end
      end
    end
  end

  describe "boundry retrieval" do
    property "lower boundry" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = a,
                upper = a + b do
        period = Period.new!(lower, upper, lower_state: :included)
        assert {:included, dt} = Period.get_lower_boundry(period)
        assert lower == DateTime.to_unix(dt, :microseconds)
        assert "[" == Period.get_lower_boundry_notation(period)

        period = Period.new!(lower, upper, lower_state: :excluded)
        assert {:excluded, dt} = Period.get_lower_boundry(period)
        assert lower == DateTime.to_unix(dt, :microseconds)
        assert "(" == Period.get_lower_boundry_notation(period)
      end
    end

    property "upper boundry" do
      check all a <- positive_integer(),
                b <- positive_integer(),
                lower = a,
                upper = a + b do
        period = Period.new!(lower, upper, upper_state: :included)
        assert {:included, dt} = Period.get_upper_boundry(period)
        assert upper == DateTime.to_unix(dt, :microseconds)
        assert "]" == Period.get_upper_boundry_notation(period)

        period = Period.new!(lower, upper, upper_state: :excluded)
        assert {:excluded, dt} = Period.get_upper_boundry(period)
        assert upper == DateTime.to_unix(dt, :microseconds)
        assert ")" == Period.get_upper_boundry_notation(period)
      end
    end
  end

  describe "make_inclusive/1" do
    test "both exclusive" do
      period = Period.new!(0, 2, lower_state: :excluded, upper_state: :excluded)
      expect = Period.new!(1, 1, lower_state: :included, upper_state: :included)

      assert expect == Period.make_inclusive(period)
    end

    test "lower exclusive" do
      period = Period.new!(0, 1, lower_state: :excluded, upper_state: :included)
      expect = Period.new!(1, 1, lower_state: :included, upper_state: :included)

      assert expect == Period.make_inclusive(period)
    end

    test "upper exclusive" do
      period = Period.new!(1, 2, lower_state: :included, upper_state: :excluded)
      expect = Period.new!(1, 1, lower_state: :included, upper_state: :included)

      assert expect == Period.make_inclusive(period)
    end

    test "none exclusive" do
      period = Period.new!(1, 1, lower_state: :included, upper_state: :included)

      assert period == Period.make_inclusive(period)
    end
  end
end
