defmodule Exsible do
  @moduledoc """
  Documentation for Exsible.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Exsible.hello
      :world

  """
  def hello do
    :world
  end

  def mod_args_json do
    %{
      ANSIBLE_MODULE_ARGS: %{
        _raw_params: "cat /etc/os-release"
      }
    } |> Poison.encode!
  end

  def mod_path do
    "ansible-2.2.1.0/lib/ansible/modules/core/commands/command.py"
  end

  def zip_initial_contents do
    [
      {
        'ansible/__init__.py',
        "from pkgutil import extend_path\n__path__=extend_path(__path__,__name__)\n" <>
        "__version__=\"2.2.1.0\"\n" <>
        "__author__=\"Ansible, Inc.\"\n"
      },
      {
        'ansible/module_utils/__init__.py',
        "from pkgutil import extend_path\n__path__=extend_path(__path__,__name__)\n"
      },
      {
        'ansible_module_command.py',
        File.read!("ansible-2.2.1.0/lib/ansible/modules/core/commands/command.py")
      },
      {
        'ansible/module_utils/basic.py',
        File.read!("ansible-2.2.1.0/lib/ansible/module_utils/basic.py")
      },
      {
        'ansible/module_utils/six.py',
        File.read!("ansible-2.2.1.0/lib/ansible/module_utils/six.py")
      },
      {
        'ansible/module_utils/pycompat24.py',
        File.read!("ansible-2.2.1.0/lib/ansible/module_utils/pycompat24.py")
      },
      {
        'ansible/module_utils/_text.py',
        File.read!("ansible-2.2.1.0/lib/ansible/module_utils/_text.py")
      }
    ]
  end

  def zipdata do
    {:ok, {_, deflated_bin}} = :zip.create('name.zip', zip_initial_contents(), [:memory])
    Base.encode64(deflated_bin)
  end

  def render do
    now = DateTime.utc_now
    params = [
      coding:         "# -*- coding: utf-8 -*-",
      interpreter:    "/usr/bin/python",
      shebang:        "#!/usr/bin/python",
      zipdata:        zipdata(), # command mod and its dependencies
      ansible_module: "command",
      params:         mod_args_json(),
      year:           now.year,
      month:          now.month,
      day:            now.day,
      hour:           now.hour,
      minute:         now.minute,
      second:         now.second
    ]

    EEx.eval_file("apps/exsible/lib/templates/ansiballz.eex", params)
  end

  def read_stdin() do
    IO.read(:stdio, :all)
  end

  def validate_against_schema(doc) do
    File.read!("../exsible/test/fixtures/schema.json")
    |> Poison.decode!
    |> ExJsonSchema.Schema.resolve
    |> ExJsonSchema.Validator.validate(
      doc
      |> Poison.decode!)
  end

  def decode_tasks(json_string) do
    Poison.Parser.parse!(json_string)
    |> Map.get("tasks")
    |> Enum.reduce([],
      fn({type,obj}, acc) ->
        Enum.map(obj,
          fn({id,task}) ->
            wrapped_struct =
              ["Elixir", "Exsible", Macro.camelize(type)]
              |> Enum.join(".")
              |> String.to_atom
              |> struct(task["args"] |> Enum.map(fn {k,v} -> {String.to_atom(k),v} end))
            struct(Exsible.Task, %{id: id, args: wrapped_struct})
          end
        )
        ++ acc
      end)
  end

  def start_tasks(tasks) do
    # invoke the start() function for each task's module
    Enum.each(tasks,
              fn(t) ->
                # M/F/A...
                apply(t.args.__struct__, :start, [t.id, t.args])
              end)
  end

  def main(_args) do
    read_stdin()
    |> decode_tasks()
    |> Exsible.Walker.start
    |> Exsible.Walker.construct
    |> Exsible.Walker.walk_init
  end

  def test() do
    {:ok, _} = Registry.start_link(:unique, Registry.Tasks)

    json_string = File.read!("../exsible/test/fixtures/3hosts.json")
    :ok = validate_against_schema(json_string)

    json_string
    |> decode_tasks()
    |> Exsible.Walker.start
    |> Exsible.Walker.construct
    |> Exsible.Walker.walk_init
  end
end
