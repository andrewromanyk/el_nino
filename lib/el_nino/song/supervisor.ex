defmodule ElNino.Song.Supervisor do
  # dynamic supervisor
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_manager_queue_pair(guild_id) do
    # Start a new SongManager process for the guild
    {:ok, manager_pid} =
      DynamicSupervisor.start_child(__MODULE__, {ElNino.SongManager, [guild_id]})

    # Start a new SongQueue process for the guild
    {:ok, queue_pid} = DynamicSupervisor.start_child(__MODULE__, {ElNino.SongQueue, [guild_id]})

    {manager_pid, queue_pid}
  end

  def pair_exists?(guild_id) do
    with [{_manager_pid, _value}] <-
           Registry.lookup(
             GuildSongManagerRegistry,
             ElNino.Common.via_guild_manager_registry(guild_id)
           ),
         [{_queue_pid, _value}] <-
           Registry.lookup(
             GuildSongQueueRegistry,
             ElNino.Common.via_guild_queue_registry(guild_id)
           ) do
      true
    else
      _ -> false
    end
  end

  def terminate_manager_queue_pair(guild_id) do
    GenServer.cast(ElNino.Common.via_guild_manager_registry(guild_id), :terminate)
    Agent.stop(ElNino.Common.via_guild_queue_registry(guild_id))
  end
end
