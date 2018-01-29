defmodule Period.Relationship do
  @moduledoc """
  Does work with relationships between two `Period`'s.
  """

  @typep relationship ::
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
  Determine if the first period is before the second one.

  Being before the other period means having no overlap, but the periods might
  directly abut each other.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_before?(a, b)
      true

  """
  @spec is_before?(Period.t(), Period.t()) :: boolean
  @spec is_before?(Period.t(), Period.t(), keyword) :: boolean
  def is_before?(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :before -> true
      :abut_right -> true
      _ -> false
    end
  end

  @doc """
  Determine if the first period is after the second one.

  Being after the other period means having no overlap, but the periods might
  directly abut each other.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.is_after?(b, a)
      true

  """
  @spec is_after?(Period.t(), Period.t()) :: boolean
  @spec is_after?(Period.t(), Period.t(), keyword) :: boolean
  def is_after?(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :after -> true
      :abut_left -> true
      _ -> false
    end
  end

  @doc """
  Determine if the periods abut each other.

  Being about means having no overlap, but having no gap:

  ### End exclusive - Start inclusive

  ```markdown
  … . . .)
       [. . . …
  ```

  ### End inclusive - Start exclusive

  ```markdown
  … . . .]
       (. . . …
  ```

  ### Both inclusive

  ```markdown
  … . .]
       [. . . …
  ```

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.abut?(a, b) && Period.Relationship.abut?(b, a)
      true

  """
  @spec abut?(Period.t(), Period.t()) :: boolean
  @spec abut?(Period.t(), Period.t(), keyword) :: boolean
  def abut?(%Period{} = a, %Period{} = b, opts \\ []) do
    is_abutted_left?(a, b, opts) || is_abutted_right?(a, b, opts)
  end

  @doc """
  Determine if the first period is abutted on it's left side by the second period.

  For details on what `abut` means, see: `abut?/3`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> Period.Relationship.is_abutted_left?(a, b)
      true

  """
  @spec is_abutted_left?(Period.t(), Period.t()) :: boolean
  @spec is_abutted_left?(Period.t(), Period.t(), keyword) :: boolean
  def is_abutted_left?(%Period{} = a, %Period{} = b, opts \\ []) do
    :abut_left == period_relationship(a, b, opts)
  end

  @doc """
  Determine if the first period is abutted on it's right side by the second period.

  For details on what `abut` means, see: `abut?/3`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> Period.Relationship.is_abutted_right?(b, a)
      true

  """
  @spec is_abutted_right?(Period.t(), Period.t()) :: boolean
  @spec is_abutted_right?(Period.t(), Period.t(), keyword) :: boolean
  def is_abutted_right?(%Period{} = a, %Period{} = b, opts \\ []) do
    :abut_right == period_relationship(a, b, opts)
  end

  @doc """
  Determine if the first period overlaps the second one.

  Overlaping means having being at least one common point:

  ### End exclusive - Start inclusive

  ```markdown
  … . . .)
     [. . . . …
  ```

  ### End inclusive - Start exclusive

  ```markdown
  … . . .]
     (. . . . …
  ```

  ### Both inclusive

  ```markdown
  … . .]
     [. . . . …
  ```

  ### Both exclusive

  ```markdown
  … . . . .)
     (. . . . …
  ```

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.overlaps?(a, b)
      true

  """
  @spec overlaps?(Period.t(), Period.t()) :: boolean
  @spec overlaps?(Period.t(), Period.t(), keyword) :: boolean
  def overlaps?(%Period{} = a, %Period{} = b, opts \\ []) do
    case period_relationship(a, b, opts) do
      :intersect_start -> true
      :intersect_end -> true
      :contains -> true
      :contained -> true
      _ -> false
    end
  end

  @doc """
  Determine if the first period contains the second one.

  Containment means having being at least the same period as the second one, but
  overlaping it on at least one side:

  ### Overlap both ends

  ```markdown
  [. . . . . . .]
    [. . . . .]
  ```

  ### Overlap start

  ```markdown
  [. . . . . . .]
    [. . . . . .]
  ```

  ### Overlap end

  ```markdown
  [. . . . . . .]
  [. . . . . .]
  ```

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 18:32:21], ~N[2017-11-22 07:32:21])
      iex> Period.Relationship.contains?(a, b)
      true

  """
  @spec contains?(Period.t(), Period.t()) :: boolean
  @spec contains?(Period.t(), Period.t(), keyword) :: boolean
  def contains?(%Period{} = a, %Period{} = b, opts \\ []) do
    :contains == period_relationship(a, b, opts)
  end

  @doc """
  Determine if the first period is contained by the second one.

  For details on what `contained` means, see: `contains?/3`.

  ```

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 18:32:21], ~N[2017-11-22 07:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> Period.Relationship.is_contained_by?(a, b)
      true

  """
  @spec is_contained_by?(Period.t(), Period.t()) :: boolean
  @spec is_contained_by?(Period.t(), Period.t(), keyword) :: boolean
  def is_contained_by?(%Period{} = a, %Period{} = b, opts \\ []) do
    contains?(b, a, opts)
  end

  @doc """
  Determine if both periods span the same time.

  ## Non-strict comparison

  ### Simple

  ```markdown
  [. . . . .]
  [. . . . .]
  ```

  ### Exclusive overlap start

  ```markdown
  (. . . . . . .]
    [. . . . . .]
  ```

  ### Exclusive overlap end

  ```markdown
  [. . . . . . .)
  [. . . . . .]
  ```

  ## Strict comparison

  For strict comparison timespan and boundry states need to be the same.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> Period.Relationship.same?(a, b)
      true

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> Period.Relationship.same?(a, b, strict: true)
      true

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21.000001])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21], upper_state: :included)
      iex> Period.Relationship.same?(a, b)
      true

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21.000001])
      iex> b = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21], upper_state: :included)
      iex> Period.Relationship.same?(a, b, strict: true)
      false

  """
  @spec same?(Period.t(), Period.t()) :: boolean
  @spec same?(Period.t(), Period.t(), keyword) :: boolean
  def same?(%Period{} = a, %Period{} = b, opts \\ []) do
    with :same <- period_relationship(a, b, opts) do
      if Keyword.get(opts, :strict, false) do
        Period.get_boundry_notation(a) == Period.get_boundry_notation(b)
      else
        true
      end
    else
      _ -> false
    end
  end

  @doc """
  If both periods overlap returns a new period of the intersection of both.

  For details on what `overlapping` means, see: `overlaps?/3`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-22 14:32:21])
      iex> b = Period.from_naive!(~N[2017-11-21 10:29:12], ~N[2017-11-23 10:29:12])
      iex> {:ok, period} = Period.Relationship.intersection(a, b)
      iex> period
      #Period<[#DateTime<2017-11-21 10:29:12.000000Z>, #DateTime<2017-11-22 14:32:21.000000Z>)>

  """
  @spec intersection(Period.t(), Period.t()) :: {:ok, Period.t()} | {:error, binary}
  @spec intersection(Period.t(), Period.t(), keyword) :: {:ok, Period.t()} | {:error, binary}
  def intersection(%Period{} = a, %Period{} = b, opts \\ []) do
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
  If both periods do not overlap or abut it returns a new period of the gap between both.

  For details on what `overlapping` means, see: `overlaps?/3`. For details on what `abut` means, see: `abut?/3`.

  ## Examples

      iex> a = Period.from_naive!(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      iex> b = Period.from_naive!(~N[2017-11-22 14:32:21], ~N[2017-11-23 10:29:12])
      iex> Period.Relationship.gap(a, b)
      iex> {:ok, period} = Period.Relationship.gap(a, b)
      iex> period
      #Period<[#DateTime<2017-11-21 10:29:12.000000Z>, #DateTime<2017-11-22 14:32:21.000000Z>)>

  """
  @spec gap(Period.t(), Period.t()) :: {:ok, Period.t()} | {:error, binary}
  @spec gap(Period.t(), Period.t(), keyword) :: {:ok, Period.t()} | {:error, binary}
  def gap(%Period{} = a, %Period{} = b, opts \\ []) do
    with false <- overlaps?(a, b, opts),
         false <- abut?(a, b, opts) do
      [a, b] = Enum.sort([a, b], &is_before?/2)

      opts = [
        lower_state: invert_inclusion(a.upper_state),
        upper_state: invert_inclusion(b.lower_state)
      ]

      Period.new(a.upper, b.lower, opts)
    else
      true -> {:error, "Periods intersect or abut each other."}
    end
  end

  @spec invert_inclusion(Period.boundry_state()) :: Period.boundry_state()
  defp invert_inclusion(:included), do: :excluded
  defp invert_inclusion(:excluded), do: :included

  @spec period_relationship(Period.t(), Period.t(), Keyword.t()) :: relationship
  defp period_relationship(%Period{} = a, %Period{} = b, _opts) do
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
