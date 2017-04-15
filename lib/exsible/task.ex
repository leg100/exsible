defmodule Exsible.Task do
  defstruct ~W[id args]a

  defmacro __using__(_opts) do
    quote do
      use GenServer

      Module.register_attribute __MODULE__, :reference, accumulate: true

      def references(mod) do
        Enum.map(@reference, fn(attr) -> mod[attr] end)
      end

      def start(id, mod) do
        name = {:via, Registry, {Registry.Tasks, id}}
        GenServer.start(__MODULE__, mod, name: name)
      end

      def run(id) do
        GenServer.cast(id, {:run, self()})
      end

      def stop(id) do
        GenServer.stop(id)
      end
    end
  end
end
