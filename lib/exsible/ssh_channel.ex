defmodule Exsible.SSHChannel do
  use GenServer

  defstruct conn_ref: nil, channel_id: nil, client: nil, stdout: "", stderr: "", exit_status: nil, closed: false

  # interface

  def start(conn_ref) do
    {:ok, pid} = GenServer.start(__MODULE__, conn_ref)
    pid
  end

  def run_cmd(pid, cmd, client) do
    GenServer.cast(pid, {:run_cmd, cmd, client})
  end

  # callbacks

  def init(conn_ref) do
    {:ok, channel_id} = :ssh_connection.session_channel(conn_ref, 5000)
    {:ok, %Exsible.SSHChannel{conn_ref: conn_ref, channel_id: channel_id}}
  end

  def handle_cast({:run_cmd, cmd, client}, channel) do
    :success = :ssh_connection.exec(channel.conn_ref, channel.channel_id, String.to_charlist(cmd), 5000)

    {:noreply, %{channel | client: client}}
  end

  def handle_info({:ssh_cm, _, {:data, _, 0, stdout}}, channel) do
    {:noreply, %{channel | stdout: channel.stdout <> stdout}}
  end

  def handle_info({:ssh_cm, _, {:data, _, 1, stderr}}, channel) do
    {:noreply, %{channel | stderr: channel.stderr <> stderr}}
  end

  def handle_info({:ssh_cm, _, {:exit_status, _, exit_status}}, channel) do
    {:noreply, %{channel | exit_status: exit_status}}
  end

  def handle_info({:ssh_cm, _, {:eof, _}}, channel) do
    {:noreply, channel}
  end

  def handle_info({:ssh_cm, _, {:closed, _}}, channel) do
    GenServer.reply(channel.client, {channel.stdout, channel.stderr, 0})
    {:stop, :normal, %{channel | closed: true}}
  end
end
