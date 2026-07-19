defmodule ElNino.ChannelStore do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    Process.flag(:trap_exit, true)

    table_path = ~c"channels.dets"
    {:ok, ref} = :dets.open_file(:channel_store, type: :set, file: table_path)

    {:ok, %{table: ref}}
  end

  @impl true
  def terminate(_reason, state) do
    :dets.close(state.table)
  end

  def put(guild_id, channel_id) do
    GenServer.call(__MODULE__, {:put, guild_id, channel_id})
  end

  def get(guild_id) do
    GenServer.call(__MODULE__, {:get, guild_id})
  end

  @impl true
  def handle_call({:put, guild_id, channel_id}, _from, state) do
    :dets.insert(state.table, {guild_id, channel_id})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get, guild_id}, _from, state) do
    case :dets.lookup(state.table, guild_id) do
      [{^guild_id, channel_id}] -> {:reply, {:ok, channel_id}, state}
      [] -> {:reply, :error, state}
    end
  end
end
