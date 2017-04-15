defmodule Exsible.PubKeyHandler do
  @behaviour :ssh_client_key_api

  def add_host_key(_hostnames, _key, _connect_opts) do
    :ok
  end

  def is_host_key(_key, _host, _algorithm, _connect_opts) do
    true
  end

  def user_key(_algorithm, connect_opts) do
    {:ok, str} = File.read connect_opts[:key_cb_private][:identity_file]

    key = :public_key.pem_decode(str)
          |> List.first
          |> :public_key.pem_entry_decode

    {:ok, key}
  end
end
