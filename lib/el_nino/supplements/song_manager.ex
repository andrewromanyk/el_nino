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

  def pause do
    GenServer.call(__MODULE__, :pause)
  end

  def connected(guild_id) do
    GenServer.call(__MODULE__, {:connected, guild_id})
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
        Logger.info("SongManager: Received play command while not connected. Waiting for connection.")
        {:reply, {:ok, "Connecting to voice channel."}, {:connecting, song}}

      :waiting ->
        Logger.info("SongManager: Received play command while waiting. Updating song to #{song}.")
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: ElNino.Lavalink.Client.load_tracks(song)
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
          encoded_track: ElNino.Lavalink.Client.load_tracks(song)
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
  def handle_call(:pause, _from, {status, current_song} = state) do
    case status do
      :playing ->
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          :persistent_term.get(:guild_id),
          paused: true
        )

        {:reply, {:ok, "Paused."}, {:paused, current_song}}

      _ ->
        {:noreply, state}
    end
  end
end
