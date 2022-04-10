defmodule Mycelium.Colony.Authenticator do
  @behaviour :ssh_server_key_api
  @moduledoc """
  Authenticates fungus.
  """

  require Logger
  use GenServer

  # :ssh_server_key_api callbacks

  def host_key(algorithm, daemon_options) do
    :ssh_file.host_key(algorithm, daemon_options)
  end

  def is_auth_key(public_user_key, user, _daemon_options) do
    Logger.debug("New authentication trial: #{inspect(user)}:#{inspect(public_user_key)}")

    {_kind, _algo, pub_key} = public_user_key

    authenticate_fungus(user, pub_key)
  end

  # GenServer callbacks

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__] ++ opts)
  end

  def init(_args) do
    file = Application.fetch_env!(:mycelium, :authenticator_backend_file) |> String.to_charlist()

    {:ok, table} =
      :dets.open_file(:colony_authenticator,
        type: :set,
        file: file
      )

    Logger.info("[STARTED] Mycelium Colony Authenticator Backend")

    {:ok, table}
  end

  def handle_call({:create_fungus, %{name: name, public_key: public_key}}, _from, state) do
    [{{:ed_pub, :ed25519, content}, _comment}] = :ssh_file.decode(public_key, :public_key)

    case :dets.insert(state, {name, content}) do
      :ok -> {:reply, :ok, state}
      error -> {:reply, error, state}
    end
  end

  def handle_call(:list_all_fungi, _from, state) do
    result = :dets.foldl(fn x, y -> [x | y] end, [], state)

    {:reply, result, state}
  end

  def handle_call({:delete_fungus, name}, _from, state) do
    result = :dets.delete(state, name)

    {:reply, result, state}
  end

  def handle_call({:match_fungus, match_pattern}, _from, state) do
    result = :dets.match_object(state, match_pattern)

    {:reply, result, state}
  end

  def terminate(reason, state) do
    :dets.close(state)

    reason
  end

  # Normal functions

  def create_fungus(params) do
    GenServer.call(__MODULE__, {:create_fungus, params})
  end

  def list_all_fungi do
    GenServer.call(__MODULE__, :list_all_fungi)
  end

  def delete_fungus(name) do
    GenServer.call(__MODULE__, {:delete_fungus, name})
  end

  def authenticate_fungus(name, public_key) do
    # Erlang strings are charlist, =/= Elixir string
    fungus_name = List.to_string(name)

    case GenServer.call(__MODULE__, {:match_fungus, {fungus_name, public_key}}) do
      [{^fungus_name, ^public_key}] -> true
      _ -> false
    end
  end
end
