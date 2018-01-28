defmodule Period.Relationship do
  @moduledoc """
  How do Periods stand in relation to each other
  """

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_before(a, b)
      true

  """
  def is_before(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :before -> true
      :abut_right -> true
      _ -> false
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_after(b, a)
      true

  """
  def is_after(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :after -> true
      :abut_left -> true
      _ -> false
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.abut(a, b) && Period.Relationship.abut(b, a)
      true

  """
  def abut(%Period{} = a, %Period{} = b, opts \\ []) do
    abut_left(a, b, opts) || abut_right(a, b, opts)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> Period.Relationship.abut_left(a, b)
      true

  """
  def abut_left(%Period{} = a, %Period{} = b, opts \\ []) do
    :abut_left == period_relationship(a, b, opts)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> Period.Relationship.abut_right(b, a)
      true

  """
  def abut_right(%Period{} = a, %Period{} = b, opts \\ []) do
    :abut_right == period_relationship(a, b, opts)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.overlaps(a, b)
      true

  """
  def overlaps(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
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

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> Period.Relationship.same_value(a, b)
      true

  """
  def same_value(%Period{} = a, %Period{} = b, opts \\ []) do
    :same == period_relationship(a, b, opts)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 18:32:21], ~N[2017-11-22 07:32:21])
      iex> Period.Relationship.contains(a, b)
      true

  """
  def contains(%Period{} = a, %Period{} = b, opts \\ []) do
    :contains == period_relationship(a, b, opts)
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> {:ok, period} = Period.Relationship.intersect(a, b)
      iex> period
      #Period<[#DateTime<2017-11-21 10:29:12.000000Z>, #DateTime<2017-11-22 14:32:21.000000Z>)>

  """
  def intersect(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :intersect_start ->
        opts = [
          lower_state: a.lower_state,
          upper_state: b.upper_state
        ]

        Period.new(a.lower, b.upper, opts)

      :intersect_end ->
        opts = [
          lower_state: b.lower_state,
          upper_state: a.upper_state
        ]

        Period.new(b.lower, a.upper, opts)

      :contains ->
        {:ok, a}

      :contained ->
        {:ok, b}

      _ ->
        {:error, "Periods do not intersect"}
    end
  end

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.gap(a, b)
      iex> {:ok, period} = Period.Relationship.gap(a, b)
      iex> period
      #Period<[#DateTime<2017-11-21 10:29:12.000000Z>, #DateTime<2017-11-22 14:32:21.000000Z>)>

  """
  def gap(%Period{} = a, %Period{} = b, opts \\ []) do
    with false <- overlaps(a, b, opts),
         false <- abut(a, b, opts) do
      [a, b] = Enum.sort([a, b], &is_before/2)

      opts = [
        lower_state: invert_inclusion(a.upper_state),
        upper_state: invert_inclusion(b.lower_state)
      ]

      Period.new(a.upper, b.lower, opts)
    else
      true -> {:error, "Periods intersect or abut each other."}
    end
  end

  defp invert_inclusion(:included), do: :excluded
  defp invert_inclusion(:excluded), do: :included

  @type relationship ::
          :same
          | :contains
          | :contained
          | :before
          | :after
          | :insertsect_start
          | :intersect_end
          | :abut_left
          | :abut_right

  @doc """
  Low level relationship between periods
  """
  @spec period_relationship(Period.t(), Period.t(), Keyword.t()) :: relationship
  def period_relationship(%Period{} = a, %Period{} = b, _opts \\ []) do
    a = Period.make_inclusive(a)
    b = Period.make_inclusive(b)

    cond do
      a.lower == b.lower && a.upper == b.upper -> :same
      a.lower <= b.lower && a.upper >= b.upper -> :contains
      a.lower >= b.lower && a.upper <= b.upper -> :contained
      a.lower < b.lower && a.upper in b.lower..b.upper -> :intersect_end
      a.upper > b.upper && a.lower in b.lower..b.upper -> :intersect_start
      a.upper + 1 == b.lower -> :abut_right
      a.lower - 1 == b.upper -> :abut_left
      a.upper < b.lower -> :before
      a.lower > b.upper -> :after
    end
  end
end
