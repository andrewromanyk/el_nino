defmodule ElNino.SongManager do
  use GenServer, restart: :transient
  require Logger

  alias ElNino.Common

  @doc """
  Starts the SongManager process.
  """
  def start_link([guild_id] = opts) do
    GenServer.start_link(__MODULE__, opts, name: Common.via_guild_manager_registry(guild_id))
  end

  @impl true
  def init(_opts) do
    # First val - States: not_connected, connecting, waiting (for song), playing, paused
    ## not_connected: not connected to a voice channel; idle
    ## connecting:    bot has initiated a connection to a voice channel; eagerly waiting to start doing something
    ## waiting:       bot is connected to a voice channel, eagerly waiting for a song to be added to the queue
    ## playing:       bot is connected to a voice channel and a song is currently playing
    ## paused:        bot is connected to a voice channel and a song is currently paused; new added song won't trigger playback until resumed
    # Second val - current song (encoded track) or nil if no song is currently playing
    # Third val - guild_id
    {:ok, {:not_connected, nil}}
  end

  def play(song, guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:play, song, guild_id})
  end

  def play_list(songs, guild_id) when is_list(songs) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:play_list, songs, guild_id})
  end

  def pause(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:pause, guild_id})
  end

  def resume(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:resume, guild_id})
  end

  def play_next(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:play_next, guild_id})
  end

  def volume(volume, guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:volume, volume, guild_id})
  end

  def leave(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:leave, guild_id})
  end

  def connected(guild_id) do
    Logger.info(
      "1!!!!! SongManager: Bot has connected to the voice channel for Guild #{guild_id}."
    )

    GenServer.cast(Common.via_guild_manager_registry(guild_id), {:connected, guild_id})

    Logger.info(
      "3!!!!! SongManager: Bot has connected to the voice channel for Guild #{guild_id}."
    )
  end

  def disconnected(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:disconnected, guild_id})
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
        ElNino.SongQueue.push(song, guild_id)
        {:reply, {:ok, "Song was added to the queue."}, state}
    end
  end

  @impl true
  def handle_call(
        {:play_list, [track | songs_tail] = playlist, guild_id},
        _from,
        {status, _} = state
      ) do
    case status do
      :not_connected ->
        Logger.info(
          "SongManager: Received play_list command while not connected. Waiting for connection."
        )

        # Push all songs to the queue
        ElNino.SongQueue.push_list(songs_tail, guild_id)

        {:reply, {:ok, "Connecting to voice channel."}, {:connecting, track}}

      :waiting ->
        Logger.info(
          "SongManager: Received play command while waiting. Updating song to #{track}."
        )

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: track
        )

        ElNino.SongQueue.push_list(songs_tail, guild_id)

        {:reply, {:ok, "Song is now playing."}, {:playing, track}}

      _ ->
        Logger.info(
          "SongManager: Received play_list command while #{status}. Adding songs to queue."
        )

        ElNino.SongQueue.push_list(playlist, guild_id)
        {:reply, {:ok, "Songs were added to the queue."}, state}
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

        {:reply, {:ok, "Playback has been paused."}, {:paused, current_song}}

      :paused ->
        {:reply, {:error, "Playback is already paused."}, state}

      _ ->
        {:reply, {:error, "Cannot pause."}, state}
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

        {:reply, {:ok, "Playback was resumed."}, {:playing, current_song}}

      :playing ->
        {:reply, {:error, "Track is already playing."}, state}

      _ ->
        {:reply, {:error, "Unknown status."}, state}
    end
  end

  @impl true
  def handle_call({:leave, guild_id}, _from, _state) do
    ElNino.Lavalink.Client.destroy_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id
    )

    :ets.delete(:voice_states, guild_id)
    ElNino.SongQueue.clear(guild_id)
    Nostrum.Voice.leave_channel(guild_id)
    {:reply, {:ok, "Left voice channel."}, {:not_connected, nil}}
  end

  @impl true
  def handle_call({:disconnected, guild_id}, _from, _state) do
    Logger.info(
      "SongManager: Bot has been disconnected from the voice channel for Guild #{guild_id}."
    )

    ElNino.Lavalink.Client.destroy_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id
    )

    :ets.delete(:voice_states, guild_id)
    {:reply, {:ok, "Disconnected from voice channel."}, {:not_connected, nil}}
  end

  @impl true
  def handle_call({:play_next, guild_id}, _from, {status, _} = _state) do
    case status do
      :playing ->
        Logger.info("SongManager: Received play_next command. Playing next song.")

        case ElNino.SongQueue.pop(guild_id) do
          nil ->
            Logger.info("SongManager: No more songs in the queue. Waiting for new songs.")

            ElNino.Lavalink.Client.update_player(
              :persistent_term.get(:lavalink_session_id),
              guild_id,
              encoded_track: nil
            )

            {:reply, {:ok, "No more songs in the queue."}, {:waiting, nil}}

          next_song ->
            Logger.info("SongManager: Playing next song from queue: #{next_song}.")

            ElNino.Lavalink.Client.update_player(
              :persistent_term.get(:lavalink_session_id),
              guild_id,
              encoded_track: next_song
            )

            {:reply, {:ok, "Playing next song."}, {:playing, next_song}}
        end

      :disconnected ->
        Logger.info("SongManager: Received play_next command while disconnected. Ignoring.")
        {:reply, {:error, "Bot not in a voice channel."}, {:not_connected, nil}}

      :waiting ->
        Logger.info("SongManager: Received play_next command while waiting. Ignoring.")
        {:reply, {:error, "No songs in queue."}, {:waiting, nil}}

      _ ->
        Logger.info("SongManager: Received play_next command while #{status}. Skipping action.")
        {:reply, {:error, "Probably not in a voice channel."}, {:waiting, nil}}
    end
  end

  @impl true
  def handle_call({:volume, volume, guild_id}, _from, state) do
    ElNino.Lavalink.Client.update_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id,
      volume: volume
    )

    {:reply, {:ok, "Volume set to #{volume}."}, state}
  end

  @impl true
  def handle_cast({:connected, guild_id}, {status, song} = state) do
    Logger.info(
      "2!!!!! SongManager: Bot has connected to the voice channel for Guild #{guild_id}. Status: #{status}."
    )

    case status do
      :connecting ->
        Logger.info("SongManager: Connected to voice channel. Starting playback of #{song}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: song
        )

        {:noreply, {:playing, song}}

      :not_connected ->
        Logger.warning("SongManager: Received connected event while not connecting.")
        {:noreply, {:waiting, song}}

      _ ->
        {:noreply, state}
    end
  end

  @impl true
  def handle_cast(:terminate, _state) do
    {:stop, :normal, nil}
  end
end
