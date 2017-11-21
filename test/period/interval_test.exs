defmodule Period.IntervalTest do
  use ExUnit.Case
  # use ExUnitProperties
  # import Generators

  alias Period.Interval

  test "is_before/2" do
    base = Period.new!(~N[2017-11-20 09:32:21], ~N[2017-11-22 17:29:12])

    assert [a, b, c] = Interval.per_day_slots(base)

    assert ^a = Period.new!(~N[2017-11-20 09:32:21], ~N[2017-11-20 17:29:12])
    assert ^b = Period.new!(~N[2017-11-21 09:32:21], ~N[2017-11-21 17:29:12])
    assert ^c = Period.new!(~N[2017-11-22 09:32:21], ~N[2017-11-22 17:29:12])
  end

end
