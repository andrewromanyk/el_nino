defmodule ElNino.SongManager do
  use GenServer
  require Logger

  @doc """
  Starts the SongManager process.
  """
  def start_link(opts) do
    # This triggers the init/1 callback below
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def play(song, guild_id) do
    GenServer.call(__MODULE__, {:play, song, guild_id})
  end

  def pause(guild_id) do
    GenServer.call(__MODULE__, {:pause, guild_id})
  end

  def resume(guild_id) do
    GenServer.call(__MODULE__, {:resume, guild_id})
  end

  def leave(guild_id) do
    GenServer.call(__MODULE__, {:leave, guild_id})
  end

  def connected(guild_id) do
    GenServer.call(__MODULE__, {:connected, guild_id})
  end

  def disconnected(guild_id) do
    GenServer.call(__MODULE__, {:disconnected, guild_id})
  end

  @impl true
  def init(_args) do
    # 1st element - states: not_connected, connecting, waiting (for song), playing, paused
    # paused means even if its empty and we add a song, it wont be played.
    # waiting means if it gets a song, it till immediately play it.
    # 2nd element - current song: string supplied when calling /play command
    {:ok, {:not_connected, nil}}
  end

  @impl true
  def handle_call({:play, song, guild_id}, _from, {status, _} = state) do
    case status do
      :not_connected ->
        Logger.info(
          "SongManager: Received play command while not connected. Waiting for connection."
        )

        {:reply, {:ok, "Connecting to voice channel."}, {:connecting, song}}

      :waiting ->
        Logger.info("SongManager: Received play command while waiting. Updating song to #{song}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: song
        )

        {:reply, {:ok, "Song is now playing."}, {:playing, song}}

      _ ->
        Logger.info("SongManager: Received play command while #{status}. Adding song to queue.")
        ElNino.SongQueue.push(song)
        {:reply, {:ok, "Song was added to the queue."}, state}
    end
  end

  @impl true
  def handle_call({:connected, guild_id}, _from, {status, song} = state) do
    case status do
      :connecting ->
        Logger.info("SongManager: Connected to voice channel. Starting playback of #{song}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: song
        )

        {:reply, {:ok, "Song is now playing."}, {:playing, song}}

      :not_connected ->
        Logger.warning("SongManager: Received connected event while not connecting.")
        {:noreply, {:waiting, song}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:pause, guild_id}, _from, {status, current_song} = state) do
    case status do
      :playing ->
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          paused: true
        )

        {:reply, {:ok, "Paused."}, {:paused, current_song}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:resume, guild_id}, _from, {status, current_song} = state) do
    case status do
      :paused ->
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          paused: false
        )

        {:reply, {:ok, "Resumed."}, {:playing, current_song}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_call({:leave, guild_id}, _from, _state) do
    ElNino.Lavalink.Client.destroy_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id
    )

    :ets.delete(:voice_states, guild_id)
    ElNino.SongQueue.clear()
    Nostrum.Voice.leave_channel(guild_id)
    {:reply, {:ok, "Left voice channel."}, {:not_connected, nil}}
  end

  @impl true
  def handle_call({:disconnected, guild_id}, _from, _state) do
    ElNino.Lavalink.Client.destroy_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id
    )

    :ets.delete(:voice_states, guild_id)
    ElNino.SongQueue.clear()
    {:reply, {:ok, "Disconnected from voice channel."}, {:not_connected, nil}}
  end

  @impl true
  def handle_call({:play_next}, _from, _) do
    case ElNino.SongQueue.pop() do
      nil ->
        Logger.info("SongManager: No more songs in the queue. Waiting for new songs.")
        {:reply, {:ok, "No more songs in the queue."}, {:waiting, nil}}

      next_song ->
        Logger.info("SongManager: Playing next song from queue: #{next_song}.")
        {:reply, {:ok, "Playing next song: #{next_song}."}, {:playing, next_song}}
    end
  end
end
