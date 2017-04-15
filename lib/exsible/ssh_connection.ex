defmodule Exsible.SSHConnection do
  use Exsible.Task

  defstruct ~W[address port user identity_file]a

  # task interface

  def run_cmd(pid, cmd) do
    GenServer.call(pid, {:run_cmd, cmd})
  end

  def init(%__MODULE__{} = ssh_connection) do
    {:ok, ssh_connection}
  end

  def handle_call({:run_cmd, cmd}, from, {task, conn_ref}) do
    Exsible.SSHChannel.start(conn_ref)
    |> Exsible.SSHChannel.run_cmd(cmd, from)

    {:noreply, {task, conn_ref}}
  end

  def handle_call(:disconnect, _from, {task, conn_ref}) do
    :ok = :ssh.close(conn_ref)
    {:stop, :disconnect, :ok, task}
  end

  def handle_cast({:run, dispatcher_pid}, task) do
    {:ok, conn_ref} = connect_to_host(task.args)

    send dispatcher_pid, {:completed, Process.whereis(self())}

    # task, conn_ref, clients
    {:noreply, {task, conn_ref}}
  end

  def handle_info(msg, {task, conn_ref}) do
    IO.puts "handle_info(): #{inspect msg}"

    {:noreply, {task, conn_ref}}
  end

  def terminate(:normal, task) do
    # nothing yet
  end

  # consider putting this in the host struct
  defp connect_to_host(host) do
    :ssh.connect(
      String.to_charlist(host["address"]),
      host["port"],
      silently_accept_hosts: true,
      user:                  String.to_charlist(host["user"]),
      key_cb:                {
        Exsible.PubKeyHandler,
        identity_file:       String.to_charlist(host["identity_file"])
      }
    )
  end
end
