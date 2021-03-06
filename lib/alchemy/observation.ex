defmodule Alchemy.Observation do
  @milliseconds 1_000

  defstruct [
    duration: nil,
    value: nil,
    error: nil,
    cleaned_value: nil
  ]

  def run({type, function}, cleaner) do
    {duration, {value, error}} = :timer.tc(fn -> run_safely(function) end)

    observation = %__MODULE__{
      duration: duration / @milliseconds,
      value: value,
      cleaned_value: cleaner.(value),
      error: error,
    }

    {type, observation}
  end

  defp run_safely(f) do
    {f.(), nil}
  rescue e ->
    {nil, %{error: e, stacktrace: __STACKTRACE__}}
  end
end
