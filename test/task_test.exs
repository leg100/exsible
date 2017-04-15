defmodule TaskTest do
  use ExUnit.Case
  doctest Exsible.Task

  setup_all do
    #docker_compose_up()
    #on_exit(&docker_compose_down/0)

    tasks = [
      %Exsible.Task{ id: "a"},
      %Exsible.Task{ id: "b", args: %{"ref" => %{"$ref" => "a"}}}
    ]

    {:ok, %{tasks: tasks}}
  end

  test "Resolves references", %{tasks: tasks} do
    refs = Exsible.Task.refs(tasks, List.last(tasks))

    assert length(refs) == 1
    assert refs == [%Exsible.Task{ id: "a"}]
  end
end
