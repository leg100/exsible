defmodule SSHConnectionTest do
  use ExUnit.Case
  doctest SSHConnection

  def docker_compose_up do
    File.cd!("test", fn -> System.cmd("docker-compose", ["up", "-d"]) end)
  end

  def docker_compose_down do
    File.cd!("test", fn -> System.cmd("docker-compose", ["down"]) end)
  end

  setup_all do
    docker_compose_up()
    on_exit(&docker_compose_down/0)


    {:ok, %{}}
  end

  test "successfully connects" do
    File.read!("test/fixtures/3hosts.json")
    |> Poison.decode!
    |> List.first
    |> Map.get("args")

    # input will most probably be a map in future
    assert SSHConnection.decode_json(state) |> is_list()
  end

  test "creates hosts" do
    state = File.read!("test/fixtures/3hosts.json")

    hosts = state
      |> SSHConnection.decode_json()
      |> Enum.map(&SSHConnection.create_host/1)

    Enum.each(hosts, fn (h) ->
      assert is_map(h)
      assert h.__struct__ == Host
    end)
  end

  test "connectivity" do
    :ssh.connect('localhost', 2222, silently_accept_hosts: true, user: 'ubuntu', key_cb: {
                 PubKeyHandler, identity_file: 'test/keys/ubuntu1/id_rsa'})
  end
end
