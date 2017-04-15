defmodule Exsible.Walker do
  use GenServer

  # interface

  def start(tasks) do
    {:ok, pid} = GenServer.start(__MODULE__, tasks)
    pid
  end

  def construct(pid) do
    :ok = GenServer.call(pid, :construct)
    pid
  end

  def walk(pid) do
    :ok = GenServer.call(pid, :walk)
    pid
  end

  def walk_init(pid) do
    :ok = GenServer.call(pid, :walk_init)
    pid
  end

  # callbacks

  def init(tasks) do
    digraph = :digraph.new()
    {:ok, {digraph, tasks}}
  end

  def handle_call(:construct, _from, {digraph, tasks}) do
    root = construct_tree(digraph, tasks)
    {:reply, :ok, {digraph, root}}
  end

  # run the root task
  def handle_call(:walk_init, _from, {digraph, root}) do
    task_mod = root.args.__struct__
    task_pid = apply(task_mod, :start, [root])
    :ok = apply(task_mod, :run, [task_pid])

    {:reply, :ok, digraph}
  end

  # now run this task
  def handle_info({:walk, task_id}, digraph) do
    dependents = :digraph.out_neighbours(digraph, task_id)

    # find out which module I am, and invoke my genserver
    GenServer.cast(task_id
    :ok = apply(task_mod, :run, [task_pid])

    {:noreply, digraph}
  end

  def handle_info({:completed, :terminate}, digraph) do
    IO.puts "finished walk"

    GenServer.stop(self(), :completed)

    {:noreply, digraph}
  end

  def handle_info({:completed, task_name}, digraph) do
    # update label to reflect completion
    :digraph.add_vertex(digraph, task_name, :completed)

    # for each of my out-neighbours, have *their* in-neighbours
    # completed?
    for out <- :digraph.out_neighbours(digraph, task_name) do
      non_completes = :digraph.in_neighbours(digraph, out)
                      |> Enum.filter(fn inn ->
                        case :digraph.vertex(digraph, inn) do
                          {_, :completed} -> false
                          {_, _} -> true
                        end
                      end)
                      |> length

      if non_completes == 0 do
        send self(), {:walk, out}
      else
        IO.puts "skipping #{out}: it still has #{non_completes} in neighbours to finish"
      end
    end

    {:noreply, digraph}
  end

  # privates

  defp construct_tree(digraph, tasks) do
    for t <- tasks do
      :digraph.add_vertex(digraph, t.id)
    end

    for t <- tasks do
      for d <- Exsible.Task.references(t.args) do
        # emanating from d, the dependency
        # incident on t, the dependent
        :digraph.add_edge(digraph, d, t.id)
      end
    end

    # add root and termination vertices, to make traversal logic
    # easier
    root = add_root_vertex(digraph)
    add_termination_vertex(digraph)
    root
  end

  def add_root_vertex(digraph) do
    # create new root vertex
    root_task = %Exsible.Task{id: "root", args: %Exsible.Msg{msg: "Root task: do nothing"}}
    root_vertex = :digraph.add_vertex(digraph, root_task)

    # add edge from new root to current root(s)
    :digraph.vertices(digraph)
    |> Enum.filter(fn v -> :digraph.in_degree(digraph, v) == 0 end)
    |> Enum.filter(fn v -> v != root_vertex end)
    |> Enum.each(fn v -> :digraph.add_edge(digraph, root_vertex, v) end)

    root_task
  end

  def add_termination_vertex(digraph) do
    # create new termination vertex
    termination_task = %Exsible.Task{id: "terminate", args: %Exsible.Msg{msg: "Termination task: do nothing"}}
    termination_vertex = :digraph.add_vertex(digraph, "terminate")

    # add edges to termination vertex from vertices with no outs
    :digraph.vertices(digraph)
    |> Enum.filter(fn v -> :digraph.out_degree(digraph, v) == 0 end)
    |> Enum.filter(fn v -> v != termination_vertex end)
    |> Enum.each(fn v -> :digraph.add_edge(digraph, v, termination_vertex) end)

    termination_task
  end
end
