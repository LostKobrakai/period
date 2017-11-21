defmodule Period do
  @moduledoc """
  Documentation for Period.
  """
  @enforce_keys [:lower, :upper, :lower_included, :upper_included]
  defstruct lower: nil,
            upper: nil,
            lower_included: true,
            upper_included: false

  @type t :: %__MODULE__{
          lower: datetime,
          upper: datetime,
          lower_included: boolean,
          upper_included: boolean
        }

  @type datetime :: NaiveDateTime.t() | DateTime.t()

  @doc """
  Does create a new `%Period{}` struct.

  It does keep two `DateTime` structs as they are, but will naivify dates if one
  of them is a `NaiveDateTime`.

  ## Examples

      iex> Period.new(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12])
      {:ok, %Period{lower: ~N[2017-11-20 14:32:21], upper: ~N[2017-11-21 10:29:12], lower_included: true, upper_included: false}}

      iex> opts = [lower_included: false, upper_included: true]
      iex> Period.new(~N[2017-11-20 14:32:21], ~N[2017-11-21 10:29:12], opts)
      {:ok, %Period{lower: ~N[2017-11-20 14:32:21], upper: ~N[2017-11-21 10:29:12], lower_included: false, upper_included: true}}

  """
  @spec new(Period.datetime(), Period.datetime(), Keyword.t()) ::
          {:ok, Period.t()} | {:error, term}
  def new(lower, upper, opts \\ [])

  def new(%DateTime{} = lower, %DateTime{} = upper, opts) do
    new_generalized(lower, upper, Keyword.put(opts, :date_module, DateTime))
  end

  def new(lower, upper, opts) do
    lower = naivify(lower)
    upper = naivify(upper)
    new_generalized(lower, upper, Keyword.put(opts, :date_module, NaiveDateTime))
  end

  @doc """
  Same as `new/3`, but does raise on errors.
  """
  @spec new(Period.datetime(), Period.datetime(), Keyword.t()) :: Period.t() | no_return
  def new!(lower, upper, opts \\ []) do
    case new(lower, upper, Keyword.put(opts, :strict, true)) do
      {:error, err} -> raise ArgumentError, err
      {:ok, period} -> period
    end
  end

  # Actual implementation of `new/3` / `new!/3`
  @spec new_generalized(Period.datetime(), Period.datetime(), Keyword.t()) ::
          {:ok, Period.t()} | {:error, term}
  defp new_generalized(lower, upper, opts) do
    comparison =
      opts
      |> Keyword.fetch!(:date_module)
      |> apply(:compare, [lower, upper])

    lb = Keyword.get(opts, :lower_included, true)
    ub = Keyword.get(opts, :upper_included, false)

    case {comparison, lb, ub} do
      {:gt, _, _} ->
        if Keyword.get(opts, :strict, false) do
          err_order(lower, upper)
        else
          new_generalized(upper, lower, opts)
        end

      {:eq, true, false} ->
        err_include_exclude(true, false)

      {:eq, false, true} ->
        err_include_exclude(false, true)

      _ ->
        period = %Period{
          lower: lower,
          upper: upper,
          lower_included: lb,
          upper_included: ub
        }

        {:ok, period}
    end
  end

  # Small helper to convert dates into naive dates
  @spec naivify(Period.datetime()) :: NaiveDateTime.t()
  defp naivify(%DateTime{} = date), do: DateTime.to_naive(date)
  defp naivify(%NaiveDateTime{} = date), do: date

  @doc """
  Get the lower boundry of the period.

  Does return the boundry date and if it's included or not.
  """
  @spec get_lower_boundry(Period.t()) :: {Period.datetime(), boolean}
  def get_lower_boundry(%Period{lower: lower, lower_included: lb}) do
    {lower, lb}
  end

  @doc """
  Get the lower boundry of the period.

  Does return the boundry date and if it's included or not.
  """
  @spec get_upper_boundry(Period.t()) :: {Period.datetime(), boolean}
  def get_upper_boundry(%Period{upper: upper, upper_included: ub}) do
    {upper, ub}
  end

  @doc """
  Convert the period into a core `%Date.Range{}`.

  Does only work for fully inclusive periods because of the same restriction
  for `Date.Range` structs.
  """
  @spec to_range(Period.t()) :: {:ok, Date.Range.t()} | {:error, term}
  def to_range(%Period{lower: lower, upper: upper, lower_included: true, upper_included: true}) do
    {:ok, Date.range(lower, upper)}
  end

  def to_range(%Period{}) do
    {:error, "Date.Range's must be inclusive on both ends"}
  end

  # Exceptions / Errors
  @spec err_order(Period.datetime(), Period.datetime()) :: {:error, term}
  defp err_order(lower, upper) do
    msg = "In strict mode the lower date cannot be before the upper date (#{lower}, #{upper})."
    {:error, msg}
  end

  @spec err_include_exclude(boolean, boolean) :: {:error, term}
  defp err_include_exclude(l, u) do
    bounds =
      case {l, u} do
        {true, false} -> "[)"
        {false, true} -> "(]"
      end

    msg =
      "Cannot hold the same date for the lower and upper bound if one boundry is included" <>
        " and the other one is not (#{bounds})."

    {:error, msg}
  end
end

defimpl Inspect, for: Period do
  import Inspect.Algebra

  def inspect(period, _opts) do
    {lower, lb} = Period.get_lower_boundry(period)
    {upper, ub} = Period.get_upper_boundry(period)

    lb_string = if lb, do: "[", else: "("
    ub_string = if ub, do: "]", else: ")"

    concat ["#Period", lb_string, inspect(lower), ", ", inspect(upper), ub_string]
  end
end
