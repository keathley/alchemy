defmodule Alchemy.ExperimentTest do
  use ExUnit.Case
  doctest Alchemy

  import Alchemy.Experiment

  test "new/1 assigns a name" do
    assert new("test").name == "test"
  end

  test "new/1 generates a unique identifier" do
    assert new("test").uuid
  end

  test "new/1 generates a default comparator" do
    assert new("test").compare
  end

  test "comparator/2 updates the comparison for the new" do
    exp =
      new("test")
      |> comparator(fn(a, b) -> a.value == b.value end)

    assert exp.compare.(%{uuid: 1, value: 1337}, %{uuid: 2, value: 1337})
  end

  test "control/2 assigns the control" do
    result =
      new("Test new")
      |> control(fn -> IO.puts "Hello world" end)

    assert Enum.count(result.behaviors) == 1
  end

  test "candidate/2 can assign multiple candidates" do
    result =
      new("test")
      |> candidate(fn -> 1 end)
      |> candidate(fn -> 2 end)
      |> candidate(fn -> 3 end)

    assert Enum.count(result.behaviors) == 3
  end

  test "run/1 yields the controls result" do
    result =
      new("Test new")
      |> control(fn -> 3 + 3 end)
      |> candidate(fn -> 3 + 4 end)
      |> run

    assert result == 6
  end

  test "run/1 does not require a candidate" do
    result =
      new("Test new")
      |> control(fn -> 3 + 3 end)
      |> run

    assert result == 6
  end

  test "errors inside of control are rethrown" do
    assert_raise ArithmeticError, fn ->
      new("errors test")
      |> control(fn -> 42 / 0 end)
      |> run
    end
  end

  test "errors are compared between control and candidate" do
    pid = self()

    spawn(fn ->
      assert_raise ArithmeticError, fn ->
        new("errors test")
        |> control(fn -> 42 / 0 end)
        |> candidate(fn -> 1337 / 0 end)
        |> comparator(fn(control, candidate) ->
          result = control == candidate
          send(pid, {:result, result})
          result
        end)
        |> run
      end
    end)

    assert_receive {:result, true}
  end

  test "errors in control are returned but not raised" do
    result =
      new("errors test")
      |> control(fn -> 42 end)
      |> candidate(fn -> 1337 / 0 end)
      |> run

    assert result == 42
  end
end

