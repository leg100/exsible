defmodule Exsible.Msg do
  use Exsible.Task

  defstruct ~W[msg]a

  def init(%__MODULE__{} = args) do
    # validate params?
    {:ok, args}
  end

  def handle_cast(pid, {:run, walker_pid}, args) do
    IO.puts args.msg

    # this is a bit silly for such a small task but this is the
    # standard for all tasks, big or small!
    send walker_pid, {:completed, Process.whereis(self())}

    {:noreply, args}
  end

  def terminate(:normal, args) do
    # nothing to do
  end
end
