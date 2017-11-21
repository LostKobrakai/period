defmodule Period.Interval do
  def per_day_slots(%Period{} = period, _unit \\ :second) do
    {_lower, lb} = Period.get_lower_boundry(period)
    {_upper, ub} = Period.get_upper_boundry(period)

    Stream.unfold({period, 0}, fn
      {step, to_add} ->
        {lower, _} = Period.get_lower_boundry(step)
        date =
          lower
          |> NaiveDateTime.to_date
          |> Date.add(to_add)

        step =
          step
          |> times_of_period_bounds()
          |> merge_times_with_date(date)
          |> period_from_tuple(lower_included: lb, upper_included: ub)

        if Period.Relationship.contains(period, step) do
          {step, {step, 1}}
        else
          {step, :stop}
        end
      :stop -> nil
    end)
    |> Enum.into([])
  end

  defp times_of_period_bounds(%Period{lower: l, upper: u}) do
    {NaiveDateTime.to_time(l), NaiveDateTime.to_time(u)}
  end

  defp merge_times_with_date({from_time, to_time}, date) do
    {:ok, a} = NaiveDateTime.new(date, from_time)
    {:ok, b} = NaiveDateTime.new(date, to_time)
    {a, b}
  end

  defp period_from_tuple({lower, upper}, opts) do
    Period.new!(lower, upper, opts)
  end
end
