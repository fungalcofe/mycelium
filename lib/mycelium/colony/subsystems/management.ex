defmodule Mycelium.Colony.Subsystems.Management do
  @behaviour :ssh_server_channel
  @moduledoc """
  Various management operations.
  """

  require Logger

  def init(args) do
    {:ok, %{}}
  end

  def handle_msg({:ssh_channel_up, channel, connection_ref}, state) do
    Logger.debug("Opening a new channel: #{inspect(channel)}:#{inspect(connection_ref)}")
    new_state = Map.put(state, :connection_ref, connection_ref)

    {:ok, new_state}
  end

  def handle_msg(msg, state) do
    Logger.debug(inspect(msg))
    Logger.debug(inspect(state))

    {:ok, state}
  end

  def handle_ssh_msg(msg, state) do
    Logger.debug(inspect(msg))
    Logger.debug(inspect(state))

    {:ok, state}
  end
end
