defmodule ExsibleTest do
  use ExUnit.Case
  doctest Exsible

  import ExUnit.CaptureIO

  def docker_compose_up do
    File.cd!("test", fn -> System.cmd("docker-compose", ["up", "-d"]) end)
  end

  def docker_compose_down do
    File.cd!("test", fn -> System.cmd("docker-compose", ["down"]) end)
  end

  setup_all do
    #docker_compose_up()
    #on_exit(&docker_compose_down/0)

    state = File.read!("test/fixtures/3hosts.json")

    {:ok, %{json_string: state}}
  end

  test "reads json from stdin", %{json_string: state} do
    # state is written to stdin for read_stdin to read
    # and then we have to write the result out for assertion
    assert state == capture_io(state, fn ->
      Exsible.read_stdin |> IO.write
    end)
  end

  test "decodes json", %{json_string: state} do
    assert Exsible.decode_tasks(state) |> is_list()
  end

  test "creates tasks", %{json_string: state} do
    state
    |> Exsible.decode_tasks()
    |> Enum.each(fn (h) ->
      assert is_map(h)
      assert h.__struct__ == Exsible.Task
    end)
  end

  test "constructs dag", %{json_string: state} do
    {:ok, root, dag} = state
      |> Exsible.decode_tasks()
      |> Exsible.Walker.start()
      |> Exsible.Walker.construct()

    # 1 root, 3 hosts, 1 cmd = 5 vertices
    # 1 root -> 3 hosts -> 3 cmds = 6 edges
    assert length(:digraph.vertices(dag)) == 5
    assert length(:digraph.edges(dag)) == 6

    assert :digraph.in_degree(dag, root) == 0
    assert :digraph.out_degree(dag, root) == 3
  end

  #test "connectivity" do
  #  :ssh.connect('localhost', 2222, silently_accept_hosts: true, user: 'ubuntu', key_cb: {
  #               PubKeyHandler, identity_file: 'test/keys/ubuntu1/id_rsa'})
  #end
end
