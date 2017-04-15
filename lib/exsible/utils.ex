defmodule Exsible.Utils do
  def convert_strings_in_nested_map_to_charlists(map) when is_map(map) do
    for {k, v} <- map, into: %{} do
      {k, convert_strings_in_nested_map_to_charlists(v)}
    end
  end

  def convert_strings_in_nested_map_to_charlists(lst) when is_list(lst) do
    Enum.map(lst, &convert_strings_in_nested_map_to_charlists/1)
  end

  def convert_strings_in_nested_map_to_charlists(str) when is_bitstring(str) do
    String.to_charlist(str)
  end

  def convert_strings_in_nested_map_to_charlists(v), do: v
end
