defmodule Period.RelationshipTest do
  use ExUnit.Case
  # use ExUnitProperties
  # import Generators
  doctest Period.Relationship

  alias Period.Relationship

  test "is_before?/2" do
    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-22 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.is_before?(a, b)

    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.is_before?(a, b)

    a =
      Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], upper_state: :included)

    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.is_before?(a, b)
  end

  test "is_after?/2" do
    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-22 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.is_after?(b, a)

    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.is_after?(b, a)

    a =
      Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], upper_state: :included)

    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.is_after?(b, a)
  end

  test "abut/2" do
    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-22 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.abut?(b, a)

    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.abut?(b, a)

    a =
      Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], upper_state: :included)

    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.abut?(b, a)
  end

  test "abut_left/2" do
    a = Period.from_naive!(~N[2017-11-22 10:29:12], ~N[2017-11-23 10:29:12])
    b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])

    refute Relationship.is_abutted_left?(a, b)

    a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
    b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])

    assert Relationship.is_abutted_left?(a, b)

    a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    b =
      Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], upper_state: :included)

    refute Relationship.is_abutted_left?(a, b)
  end

  test "abut_right/2" do
    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-22 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.is_abutted_right?(a, b)

    a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    assert Relationship.is_abutted_right?(a, b)

    a =
      Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], upper_state: :included)

    b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])

    refute Relationship.is_abutted_right?(a, b)
  end
end
