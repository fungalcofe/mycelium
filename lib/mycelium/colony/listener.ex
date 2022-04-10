defmodule Mycelium.Colony.Listener do
  @moduledoc """
  Listens for incoming connections.
  """

  require Logger
  use GenServer

  def start_link(args \\ [], opts \\ []) do
    GenServer.start_link(__MODULE__, args, [name: __MODULE__] ++ opts)
  end

  def init(_args) do
    {:ok, pid} =
      :ssh.daemon(2238,
        key_cb: Mycelium.Colony.Authenticator,
        system_dir: 'priv/sshd',
        shell: :disabled,
        subsystems: [
          {'management', {Mycelium.Colony.Subsystems.Management, []}}
        ]
      )

    Logger.info("[STARTED] Mycelium Colony listener")

    {:ok, %{pid: pid}}
  end
end
