defmodule ElNino.SongManager do
  @timeout_time 10 * 60 * 1000 # 10 minutes in milliseconds

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
  def init([guild_id]) do
    {:ok, %{guild_id: guild_id, status: :not_connected, song: nil, timer_ref: nil}}
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
    GenServer.cast(Common.via_guild_manager_registry(guild_id), {:connected, guild_id})
  end

  def disconnected(guild_id) do
    GenServer.call(Common.via_guild_manager_registry(guild_id), {:disconnected, guild_id})
  end

  @impl true
  def handle_call({:play, song, guild_id}, _from, %{status: status} = state) do
    case status do
      :not_connected ->
        Logger.info("SongManager: Received play command while not connected. Waiting for connection.")
        reply_and_update({:ok, "Connecting to voice channel."}, %{state | status: :connecting, song: song}, guild_id)

      :waiting ->
        Logger.info("SongManager: Received play command while waiting. Updating song to #{song}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: song
        )

        reply_and_update({:ok, "Song is now playing."}, %{state | status: :playing, song: song}, guild_id)

      _ ->
        Logger.info("SongManager: Received play command while #{status}. Adding song to queue.")
        ElNino.SongQueue.push(song, guild_id)
        reply_and_update({:ok, "Song was added to the queue."}, state, guild_id)
    end
  end

  @impl true
  def handle_call(
        {:play_list, [track | songs_tail] = playlist, guild_id},
        _from,
        %{status: status} = state
      ) do
    case status do
      :not_connected ->
        Logger.info("SongManager: Received play_list command while not connected. Waiting for connection.")

        ElNino.SongQueue.push_list(songs_tail, guild_id)
        reply_and_update({:ok, "Connecting to voice channel."}, %{state | status: :connecting, song: track}, guild_id)

      :waiting ->
        Logger.info("SongManager: Received play command while waiting. Updating song to #{track}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: track
        )

        ElNino.SongQueue.push_list(songs_tail, guild_id)
        reply_and_update({:ok, "Song is now playing."}, %{state | status: :playing, song: track}, guild_id)

      _ ->
        Logger.info("SongManager: Received play_list command while #{status}. Adding songs to queue.")

        ElNino.SongQueue.push_list(playlist, guild_id)
        reply_and_update({:ok, "Songs were added to the queue."}, state, guild_id)
    end
  end

  @impl true
  def handle_call({:pause, guild_id}, _from, %{status: status} = state) do
    case status do
      :playing ->
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          paused: true
        )

        reply_and_update({:ok, "Playback has been paused."}, %{state | status: :paused}, guild_id)

      :paused ->
        reply_and_update({:error, "Playback is already paused."}, state, guild_id)

      _ ->
        reply_and_update({:error, "Cannot pause."}, state, guild_id)
    end
  end

  @impl true
  def handle_call({:resume, guild_id}, _from, %{status: status} = state) do
    case status do
      :paused ->
        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          paused: false
        )

        reply_and_update({:ok, "Playback was resumed."}, %{state | status: :playing}, guild_id)

      :playing ->
        reply_and_update({:error, "Track is already playing."}, state, guild_id)

      _ ->
        reply_and_update({:error, "Unknown status."}, state, guild_id)
    end
  end

  @impl true
  def handle_call({:leave, guild_id}, _from, state) do
    Nostrum.Voice.leave_channel(guild_id)
    reply_and_update({:ok, "Left voice channel."}, %{state | status: :leaving, song: nil}, guild_id)
  end

  @impl true
  def handle_call({:disconnected, guild_id}, _from, state) do
    Logger.info("SongManager: Bot has been disconnected from the voice channel for Guild #{guild_id}.")

    ElNino.Lavalink.Client.destroy_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id
    )

    :ets.delete(:voice_states, guild_id)
    ElNino.SongQueue.clear(guild_id)

    case state.status do
      :leaving ->
        Logger.info("SongManager: Bot was leaving the voice channel for Guild #{guild_id}. No further action needed.")

      :leaving_timeout ->
        Logger.info("SongManager: Bot was inactive and left the voice channel for Guild #{guild_id}. No further action needed.")
        if channel = ElNino.Discord.Common.get_last_channel_of_interaction(state.guild_id) do
          ElNino.Response.message_with_embed(
            channel,
            ElNino.Embeds.one_liner_author("Bot has been inactive for 10 minutes and has left the voice channel.")
          )
        end

      _ ->
        Logger.info("SongManager: Bot was forefully disconnected from the voice channel for Guild #{guild_id}. Cleaning up.")
        if channel = ElNino.Discord.Common.get_last_channel_of_interaction(state.guild_id) do
          ElNino.Response.message_with_embed(
            channel,
            ElNino.Embeds.one_liner_author("Bot has been kicked from the voice channel.")
          )
        end
    end

    reply_and_update({:ok, "Disconnected from voice channel."}, %{state | status: :not_connected, song: nil}, guild_id)
  end

  @impl true
  def handle_call({:play_next, guild_id}, _from, %{status: status} = state) do
    Logger.info("SongManager: Received play_next command for guild #{guild_id}. Current status: #{status}")

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

            reply_and_update({:ok, "No more songs in the queue."}, %{state | status: :waiting, song: nil}, guild_id)

          next_song ->
            Logger.info("SongManager: Playing next song from queue: #{next_song}.")

            ElNino.Lavalink.Client.update_player(
              :persistent_term.get(:lavalink_session_id),
              guild_id,
              encoded_track: next_song
            )

            reply_and_update({:ok, "Playing next song."}, %{state | status: :playing, song: next_song}, guild_id)
        end

      :not_connected ->
        Logger.info("SongManager: Received play_next command while disconnected. Ignoring.")
        reply_and_update({:error, "Bot not in a voice channel."}, %{state | status: :not_connected, song: nil}, guild_id)

      :waiting ->
        Logger.info("SongManager: Received play_next command while waiting. Ignoring.")
        reply_and_update({:error, "No songs in queue."}, %{state | status: :waiting, song: nil}, guild_id)

      _ ->
        Logger.info("SongManager: Received play_next command while #{status}. Skipping action.")
        reply_and_update({:error, "Probably not in a voice channel."}, %{state | status: :waiting, song: nil}, guild_id)
    end
  end

  @impl true
  def handle_call({:volume, volume, guild_id}, _from, state) do
    ElNino.Lavalink.Client.update_player(
      :persistent_term.get(:lavalink_session_id),
      guild_id,
      volume: volume
    )

    reply_and_update({:ok, "Volume set to #{volume}."}, state, guild_id)
  end

  @impl true
  def handle_cast({:connected, guild_id}, %{status: status} = state) do
    case status do
      :connecting ->
        Logger.info("SongManager: Connected to voice channel. Starting playback of #{state.song}.")

        ElNino.Lavalink.Client.update_player(
          :persistent_term.get(:lavalink_session_id),
          guild_id,
          encoded_track: state.song
        )

        noreply_and_update(%{state | status: :playing}, guild_id)

      :not_connected ->
        Logger.warning("SongManager: Received connected event while not connecting.")
        noreply_and_update(%{state | status: :waiting}, guild_id)

      _ ->
        noreply_and_update(state, guild_id)
    end
  end

  @impl true
  def handle_cast(:terminate, state) do
    ElNino.InteractiveSongController.terminate(state.guild_id)

    {:stop, :normal, nil}
  end

  @impl true
  def handle_info(:inactivity_timeout, state) do
    Nostrum.Voice.leave_channel(state.guild_id)
    noreply_and_update(%{state | status: :leaving_timeout}, state.guild_id)
  end

  defp reply_and_update(response, new_state, guild_id) do
    updated_state = manage_timer(new_state)

    ElNino.InteractiveSongController.update_state(guild_id, {updated_state.status, updated_state.song})

    {:reply, response, updated_state}
  end

  defp noreply_and_update(new_state, guild_id) do
    updated_state = manage_timer(new_state)

    ElNino.InteractiveSongController.update_state(guild_id, {updated_state.status, updated_state.song})

    {:noreply, updated_state}
  end


  defp manage_timer(%{status: status, timer_ref: timer_ref} = state) do
    case status do
      s when s in [:not_connected, :connecting, :playing, :paused, :leaving, :leaving_timeout] ->
        %{state | timer_ref: cancel_timeout(timer_ref)}

      :waiting ->
        %{state | timer_ref: timer_ref || schedule_timeout()}
    end
  end

  defp schedule_timeout() do
    Process.send_after(self(), :inactivity_timeout, @timeout_time)
  end

  defp cancel_timeout(nil), do: nil
  defp cancel_timeout(timer_ref) do
    Process.cancel_timer(timer_ref)
    nil
  end
end
