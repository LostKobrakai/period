defmodule Period.Relationship do
  @moduledoc """
  How do Periods stand in relation to each other
  """

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_before(a, b)
      true

  """
  def is_before(%Period{} = a, %Period{} = b) do
    case period_relationship(a, b) do
      :before -> true
      :abut_left -> true
      _ -> false
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_after(b, a)
      true

  """
  def is_after(%Period{} = a, %Period{} = b) do
    case period_relationship(a, b) do
      :after -> true
      :abut_right -> true
      _ -> false
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.abut(a, b) && Period.Relationship.abut(b, a)
      true

  """
  def abut(%Period{} = a, %Period{} = b) do
    abut_left(a, b) || abut_right(a, b)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.abut_left(a, b)
      true

  """
  def abut_left(%Period{} = a, %Period{} = b) do
    :abut_left == period_relationship(a, b)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.abut_right(b, a)
      true

  """
  def abut_right(%Period{} = a, %Period{} = b) do
    :abut_right == period_relationship(a, b)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.new!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.overlaps(a, b)
      true

  """
  def overlaps(%Period{} = a, %Period{} = b) do
    case period_relationship(a, b) do
      :intersect_start -> true
      :intersect_end -> true
      :contains -> true
      :contained -> true
      _ -> false
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> Period.Relationship.same_value(a, b)
      true

  """
  def same_value(%Period{} = a, %Period{} = b) do
    :same == period_relationship(a, b)
  end

    @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.new!(~N[2017-11-20 18:32:21], ~N[2017-11-22 07:32:21])
      iex> Period.Relationship.contains(a, b)
      true

  """
  def contains(%Period{} = a, %Period{} = b) do
    :contains == period_relationship(a, b)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.new!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.intersect(a, b)
      {:ok, %Period{lower: ~N[2017-11-21 10:29:12], upper: ~N[2017-11-22 14:32:21], lower_included: true, upper_included: false}}

  """
  def intersect(%Period{} = a, %Period{} = b) do
    case period_relationship(a, b) do
      :intersect_start ->
        build_gap(Period.get_upper_boundry(a), Period.get_lower_boundry(b))

      :intersect_end ->
        build_gap(Period.get_lower_boundry(b), Period.get_upper_boundry(a))

      :contains ->
        {:ok, a}

      :contained ->
        {:ok, b}

      _ -> {:error, "Periods do not intersect"}
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.new!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.new!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.gap(a, b)
      {:ok, %Period{lower: ~N[2017-11-21 10:29:12], upper: ~N[2017-11-22 14:32:21], lower_included: true, upper_included: false}}

  """
  def gap(%Period{} = a, %Period{} = b) do
    with false <- overlaps(a, b),
         false <- abut(a, b) do
      [a, b] = Enum.sort([a, b], &is_before/2)
      build_gap(Period.get_upper_boundry(a), Period.get_lower_boundry(b), invert_includes: true)
    else
      true -> {:error, "Periods intersect or abut each other."}
    end
  end

  defp build_gap({end_point, eb}, {start_point, sb}, opts \\ []) do
    invert = Keyword.get(opts, :invert_includes, false)
    if invert do
      Period.new(end_point, start_point, lower_included: !eb, upper_included: !sb)
    else
      Period.new(end_point, start_point, lower_included: eb, upper_included: sb)
    end
  end

  @doc """
  Low level relationship between periods
  """
  def period_relationship(%Period{} = a, %Period{} = b) do
    lower_a = Period.get_lower_boundry(a)
    upper_a = Period.get_upper_boundry(a)
    lower_b = Period.get_lower_boundry(b)
    upper_b = Period.get_upper_boundry(b)

    order_boundries(lower_a, upper_a, lower_b, upper_b)
  end

  defp order_boundries({a, a_start}, {b, a_end}, {c, b_start}, {d, b_end}) do
    {type, spaces} = order_dates(a, b, c, d)

    check(type, spaces, a_start, a_end, b_start, b_end)
  end

  defp order_dates(a_start, a_end, b_start, b_end) do
    [_ | rest] = ordered =
      [a_start: a_start, a_end: a_end, b_start: b_start, b_end: b_end]
      |> Enum.sort_by(fn {_, v} -> v end, &(compare(&1, &2) != :gt))

    spaces =
      ordered
      |> Enum.zip(rest)
      |> Enum.map(fn {{_, a}, {_, b}} -> compare(a, b) end)

    order =
      ordered
      |> Enum.map(fn {k, _} -> k end)
      |> List.to_tuple

    potential =
      case order do
        {:a_start, :a_end,   :b_start, :b_end} -> :before
        {:a_start, :b_start, :a_end,   :b_end} -> :intersect_end
        {:a_start, :b_start, :b_end,   :a_end} -> :contains

        {:b_start, :b_end,   :a_start, :a_end} -> :after
        {:b_start, :a_start, :b_end,   :a_end} -> :intersect_start
        {:b_start, :a_start, :a_end,   :b_end} -> :contained
      end

    {potential, spaces}
  end


  def check(_, [:eq, _, :eq], a, b, a, b), do: :same

  def check(_, [:eq, _, :eq], true, true, false, false), do: :contains
  def check(_, [:eq, _, :eq], false, false, true, true), do: :contained

  def check(:before, [_, :lt, _], _, _, _, _), do: :before
  def check(:before, [_, :eq, _], _, false, false, _), do: :before
  def check(:before, [_, :eq, _], _, true, true, _), do: :intersect_end
  def check(:before, [_, :eq, _], _, _, _, _), do: :abut_left

  def check(:intersect_end, [_, :lt, _], _, _, _, _), do: :intersect_end
  def check(:intersect_end, [_, :eq, _], _, false, false, _), do: :before
  def check(:intersect_end, [_, :eq, _], _, true, true, _), do: :intersect_end
  def check(:intersect_end, [_, :eq, _], _, _, _, _), do: :abut_left

  def check(:after, [_, :lt, _], _, _, _, _), do: :after
  def check(:after, [_, :eq, _], false, _, _, false), do: :after
  def check(:after, [_, :eq, _], true, _, _, true), do: :intersect_start
  def check(:after, [_, :eq, _], _, _, _, _), do: :abut_right

  def check(:intersect_start, [_, :lt, _], _, _, _, _), do: :intersect_start
  def check(:intersect_start, [_, :eq, _], false, _, _, false), do: :after
  def check(:intersect_start, [_, :eq, _], true, _, _, true), do: :intersect_start
  def check(:intersect_start, [_, :eq, _], _, _, _, _), do: :abut_right

  def check(:contains, [_, _, :eq], _, false, _, true), do: :intersect_end
  def check(:contains, [:eq, _, _], false, _, true, _), do: :intersect_start
  def check(:contains, [_, _, _], _, _, _, _), do: :contains

  def check(:contained, [:eq, _, :eq], true, true, false, false), do: :contained
  def check(:contained, [:eq, _, :eq], false, false, true, true), do: :contains
  def check(:contained, [_, _, :eq], _, false, _, true), do: :intersect_start
  def check(:contained, [:eq, _, _], false, _, true, _), do: :intersect_end
  def check(:contained, [_, _, _], _, _, _, _), do: :contained

  defp compare(%DateTime{} = dt1, %DateTime{} = dt2) do
    DateTime.compare(dt1, dt2)
  end

  defp compare(dt1, dt2) do
    NaiveDateTime.compare(dt1, dt2)
  end
end
