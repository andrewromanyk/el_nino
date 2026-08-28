defmodule ElNino.Song.Supervisor do
  use DynamicSupervisor

  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def create_manager_queue_pair(guild_id) do
    {:ok, manager_pid} =
      DynamicSupervisor.start_child(__MODULE__, {ElNino.SongManager, [guild_id]})

    {:ok, queue_pid} = DynamicSupervisor.start_child(__MODULE__, {ElNino.SongQueue, [guild_id]})

    {manager_pid, queue_pid}
  end

  def pair_exists?(guild_id) do
    with [{_manager_pid, _value}] <-
           Registry.lookup(
             GuildSongManagerRegistry,
             guild_id
           )
           |> IO.inspect(label: "Manager Lookup"),
         [{_queue_pid, _value}] <-
           Registry.lookup(
             GuildSongQueueRegistry,
             guild_id
           )
           |> IO.inspect(label: "Queue Lookup") do
      true
    else
      _ -> false
    end
  end

  def ensure_pair_exists(guild_id) do
    if not pair_exists?(guild_id) do
      Logger.info(
        "SongManager: No manager/queue pair found for guild #{guild_id}. Creating new pair."
      )

      create_manager_queue_pair(guild_id)
    end
  end

  def terminate_manager_queue_pair(guild_id) do
    ElNino.SongManager.terminate(guild_id)
    ElNino.SongQueue.terminate(guild_id)
  end
end
