defmodule Period do
  @moduledoc """
  Period does represent a timeframe.

  ## Creating a Period

  A Period is a opaque type, so it's not meant to be directly created like
  other structs, but you should rather use `Period.new/3`, `Period.new!/3` or
  `Period.from_naive/3` to create a Period.

  Internally Period's do work with timestamps (`:microsecond` precision) so
  any DateTime values extracted from a Period will be using the default `Etc/UTC`
  timezone. The caller will be responsible to retain timezones if needed.

  ## Date.Range

  A Period can be converted into a elixir core `Date.Range` struct by using
  `Period.to_range/1`.
  """
  @enforce_keys [:lower, :upper, :lower_state, :upper_state]
  defstruct lower: nil,
            upper: nil,
            lower_state: :included,
            upper_state: :excluded

  @opaque t :: %__MODULE__{
            lower: timestamp,
            upper: timestamp,
            lower_state: boundry_state,
            upper_state: boundry_state
          }

  @typedoc "The states a boundry can be in"
  @type boundry_state :: :included | :excluded

  @typedoc "Unix timestamp in microseconds"
  @type timestamp :: integer

  @typedoc "The input types for creating a new periods"
  @type datetime :: DateTime.t() | integer

  @doc """
  Does create a new `%Period{}` struct.

  Can only be created from timestamps or `DateTime` structs, which will be
  converted to a timestamp. This period does not furtherconcern itself with
  timezones.

  Timestamps need to be in `:microsecond` precision.

  ## Examples

      iex> {:ok, period} = Period.new(1517171882222330, 1517171882222335)
      iex> period
      #Period<[#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>)>

      iex> opts = [lower_state: :excluded, upper_state: :included]
      iex> {:ok, period} = Period.new(1517171882222330, 1517171882222335, opts)
      iex> period
      #Period<(#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>]>

      iex> from = DateTime.from_unix!(1517171882222330, :microsecond)
      iex> to = DateTime.from_unix!(1517171882222335, :microsecond)
      iex> {:ok, period} = Period.new(from, to)
      iex> period
      #Period<[#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>)>

      iex> from = DateTime.from_unix!(1517171882222335, :microsecond)
      iex> to = DateTime.from_unix!(1517171882222330, :microsecond)
      iex> Period.new(from, to)
      {:error, "In strict mode the lower date cannot be before the upper date (2018-01-28 20:38:02.222335Z, 2018-01-28 20:38:02.222330Z)."}

  """
  @spec new(datetime, datetime, Keyword.t()) :: {:ok, t} | {:error, term}
  def new(lower, upper, opts \\ [])

  def new(%DateTime{} = lower, %DateTime{} = upper, opts) do
    lower = DateTime.to_unix(lower, :microsecond)
    upper = DateTime.to_unix(upper, :microsecond)
    new(lower, upper, opts)
  end

  def new(lower, upper, opts) when is_integer(lower) and is_integer(upper) do
    lb = Keyword.get(opts, :lower_state, :included)
    ub = Keyword.get(opts, :upper_state, :excluded)

    cond do
      lower > upper -> err_order(lower, upper)
      lower == upper && lb != ub -> err_include_exclude(lb, ub)
      true -> {:ok, %Period{lower: lower, upper: upper, lower_state: lb, upper_state: ub}}
    end
  end

  @doc """
  Same as `new/3`, but does raise on errors.

  ## Examples

      iex> Period.new!(1517171882222330, 1517171882222335)
      #Period<[#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>)>

      iex> opts = [lower_state: :excluded, upper_state: :included]
      iex> Period.new!(1517171882222330, 1517171882222335, opts)
      #Period<(#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>]>

      iex> from = DateTime.from_unix!(1517171882222330, :microsecond)
      iex> to = DateTime.from_unix!(1517171882222335, :microsecond)
      iex> Period.new!(from, to)
      #Period<[#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222335Z>)>

      iex> from = DateTime.from_unix!(1517171882222335, :microsecond)
      iex> to = DateTime.from_unix!(1517171882222330, :microsecond)
      iex> Period.new!(from, to)
      ** (ArgumentError) In strict mode the lower date cannot be before the upper date (2018-01-28 20:38:02.222335Z, 2018-01-28 20:38:02.222330Z).

  """
  @spec new(datetime, datetime, Keyword.t()) :: t | no_return
  def new!(lower, upper, opts \\ []) do
    case new(lower, upper, opts) do
      {:error, err} -> raise ArgumentError, err
      {:ok, period} -> period
    end
  end

  @doc """
  Convenience function to use `Period` with naive datetime values.

  Does simply attach the `Etc/UTC` timezone to the naive datetime.
  """
  @spec from_naive(NaiveDateTime.t(), NaiveDateTime.t(), Keyword.t()) :: {:ok, t} | {:error, term}
  def from_naive(%NaiveDateTime{} = from, %NaiveDateTime{} = to, opts \\ []) do
    from = DateTime.from_naive!(from, "Etc/UTC")
    to = DateTime.from_naive!(to, "Etc/UTC")
    new(from, to, opts)
  end

  @spec from_naive!(NaiveDateTime.t(), NaiveDateTime.t(), Keyword.t()) :: t | no_return
  def from_naive!(%NaiveDateTime{} = from, %NaiveDateTime{} = to, opts \\ []) do
    from = DateTime.from_naive!(from, "Etc/UTC")
    to = DateTime.from_naive!(to, "Etc/UTC")
    new!(from, to, opts)
  end

  @doc """
  Get the lower boundry of the period.

  Does return the boundry state and the date of the boundry.

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> {:included, dt} = Period.get_lower_boundry(period)
      iex> dt
      #DateTime<2018-01-28 20:38:02.222330Z>

  """
  @spec get_lower_boundry(t) :: {boundry_state, DateTime.t()}
  def get_lower_boundry(%Period{lower: lower, lower_state: lb}) do
    {lb, to_datetime(lower)}
  end

  @doc """
  Get the lower boundry of the period.

  Does return the boundry state and the date of the boundry.

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> {:excluded, dt} = Period.get_upper_boundry(period)
      iex> dt
      #DateTime<2018-01-28 20:38:02.222335Z>

  """
  @spec get_upper_boundry(t) :: {boundry_state, DateTime.t()}
  def get_upper_boundry(%Period{upper: upper, upper_state: ub}) do
    {ub, to_datetime(upper)}
  end

  @doc """
  Get the boundry notation for both boundries

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> Period.get_boundry_notation(period)
      {"[", ")"}

  """
  @spec get_boundry_notation(t) :: {binary(), binary()}
  def get_boundry_notation(%Period{} = p) do
    {get_lower_boundry_notation(p), get_upper_boundry_notation(p)}
  end

  @doc """
  Get the boundry notation for the lower boundry

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> Period.get_lower_boundry_notation(period)
      "["

      iex> period = Period.new!(1517171882222330, 1517171882222335, lower_state: :excluded)
      iex> Period.get_lower_boundry_notation(period)
      "("

  """
  @spec get_lower_boundry_notation(t) :: binary()
  def get_lower_boundry_notation(%Period{lower_state: :included}), do: "["
  def get_lower_boundry_notation(%Period{lower_state: :excluded}), do: "("

  @doc """
  Get the boundry notation for the upper boundry

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> Period.get_upper_boundry_notation(period)
      ")"

      iex> period = Period.new!(1517171882222330, 1517171882222335, upper_state: :included)
      iex> Period.get_upper_boundry_notation(period)
      "]"

  """
  @spec get_upper_boundry_notation(t) :: binary()
  def get_upper_boundry_notation(%Period{upper_state: :included}), do: "]"
  def get_upper_boundry_notation(%Period{upper_state: :excluded}), do: ")"

  @doc """
  Make a period inclusive on both ends.

  ## Example

      iex> period = Period.new!(1517171882222330, 1517171882222335)
      iex> Period.make_inclusive(period)
      #Period<[#DateTime<2018-01-28 20:38:02.222330Z>, #DateTime<2018-01-28 20:38:02.222334Z>]>

  """
  @spec make_inclusive(t) :: t
  def make_inclusive(%Period{lower: lower, lower_state: :excluded} = period) do
    %{period | lower: lower + 1, lower_state: :included}
    |> make_inclusive()
  end

  def make_inclusive(%Period{upper: upper, upper_state: :excluded} = period) do
    %{period | upper: upper - 1, upper_state: :included}
    |> make_inclusive()
  end

  def make_inclusive(period) do
    period
  end

  @doc """
  Convert the period into a core `%Date.Range{}`.

  Does only work with periods, which are inclusive on both boundries as that's a restriction
  of `Date.Range` structs.
  """
  @spec to_range(t) :: {:ok, Date.Range.t()} | {:error, term}
  def to_range(%Period{lower: lower, upper: upper, lower_state: true, upper_state: true}) do
    {:ok, Date.range(to_datetime(lower), to_datetime(upper))}
  end

  def to_range(%Period{}) do
    {:error, "Date.Range's must be inclusive on both ends"}
  end

  # Helpers
  defp to_datetime(boundry), do: DateTime.from_unix!(boundry, :microsecond)

  # Exceptions / Errors
  @spec err_order(integer, integer) :: {:error, term}
  defp err_order(lower, upper) do
    details = "(#{to_datetime(lower)}, #{to_datetime(upper)})"
    msg = "In strict mode the lower date cannot be before the upper date #{details}."

    {:error, msg}
  end

  @spec err_include_exclude(boundry_state, boundry_state) :: {:error, term}
  defp err_include_exclude(lb, ub) do
    bounds =
      %Period{lower: nil, upper: nil, lower_state: lb, upper_state: ub}
      |> get_boundry_notation()
      |> Tuple.to_list()
      |> Enum.join("")

    msg =
      "Cannot hold the same date for the lower and upper bound if one boundry is included" <>
        " and the other one is not (#{bounds})."

    {:error, msg}
  end
end

defimpl Inspect, for: Period do
  import Inspect.Algebra

  def inspect(period, _opts) do
    concat([
      "#Period<",
      Period.get_lower_boundry_notation(period),
      inspect(DateTime.from_unix!(period.lower, :microsecond)),
      ", ",
      inspect(DateTime.from_unix!(period.upper, :microsecond)),
      Period.get_upper_boundry_notation(period),
      ">"
    ])
  end
end
