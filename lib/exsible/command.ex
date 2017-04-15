defmodule Exsible.Command do
  use Exsible.Task

  defstruct ~W[command host]a

  @reference :host

  def init(%__MODULE__{} = command) do
    {:ok, command}
  end

  def handle_cast({:run, walker_pid}, command) do
    # run_cmd -> synchronous call, blocking me, not the ssh_connection
    ssh_connection_name = String.to_atom(command.host)
    {stdout, _, exit_code} = Exsible.SSHConnection.run_cmd(ssh_connection_name, command.command)
    IO.puts stdout
    IO.puts "exit status is: #{exit_code}"
    send walker_pid, {:completed, Process.whereis(self())}
    {:noreply, command}
  end

  def terminate(:normal, command) do
    # nothing to do here
  end
end
