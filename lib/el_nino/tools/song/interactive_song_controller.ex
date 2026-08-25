defmodule ElNino.InteractiveSongController do
  use GenServer, restart: :transient
  require Logger

  def start_link(guild_id) do
    GenServer.start_link(__MODULE__, guild_id, name: via_tuple(guild_id))
  end

  def update_state(guild_id, playback_state) do
    ensure_started(guild_id)
    GenServer.cast(via_tuple(guild_id), {:update_state, playback_state})
  end

  def terminate(guild_id) do
    GenServer.cast(via_tuple(guild_id), :terminate)
  end

  defp via_tuple(guild_id) do
    {:via, Registry, {GuildInteractiveSongControllerRegistry, {__MODULE__, guild_id}}}
  end

  defp ensure_started(guild_id) do
    case DynamicSupervisor.start_child(
           GuildInteractiveSongControllerSupervisor,
           {__MODULE__, guild_id}
         ) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        :ok

      error ->
        Logger.error("Failed to start song controller for guild #{guild_id}: #{inspect(error)}")
        error
    end
  end

  @impl true
  def init(guild_id) do
    {:ok, guild_id}
  end

  @impl true
  def handle_cast({:update_state, playback_state}, guild_id) do
    case ElNino.ChannelStore.get(guild_id) do
      {:ok, channel_id} ->
        {:ok, %Nostrum.Struct.Message{id: id}} = ensure_one_message(channel_id)

        Logger.info(
          "Retrieved message #{id} from channel #{channel_id} for guild #{guild_id}. Updating message with current state."
        )

        embeds = build_embeds(guild_id, playback_state)

        components =
          build_components(disable_components(playback_state), style_components(playback_state))

        {:ok, _} =
          Nostrum.Api.Message.edit(channel_id, id,
            content: "",
            embeds: embeds,
            components: components
          )

      {:error, reason} ->
        Logger.error(
          "Error retrieving manager channel for guild #{guild_id}. Reason: #{inspect(reason)}"
        )

      :not_found ->
        Logger.info("No manager channel found for guild #{guild_id}")
    end

    {:noreply, guild_id}
  end

  @impl true
  def handle_cast(:terminate, guild_id) do
    Logger.info("Terminating InteractiveSongController for guild #{guild_id}.")
    {:stop, :normal, guild_id}
  end

  defp build_embeds(guild_id, state) do
    case state do
      {:not_connected, _} ->
        [
          ElNino.Embeds.two_liner_author_description(
            "Bot is not connected to a voice channel.",
            "Use the `/play` command to start playing music."
          )
        ]

      {:connecting, _} ->
        [
          ElNino.Embeds.two_liner_author_description(
            "Bot is connecting to a voice channel.",
            "Please wait while the bot connects."
          )
        ]

      {:waiting, _} ->
        [
          ElNino.Embeds.two_liner_author_description(
            "Bot is waiting for a song to be added to the queue.",
            "Please add a song using the `/play` command."
          )
        ]

      {:leaving, _} ->
        [
          ElNino.Embeds.two_liner_author_description(
            "Bot is leaving the voice channel.",
            "No further action is needed."
          )
        ]

      {:leaving_timeout, _} ->
        [
          ElNino.Embeds.two_liner_author_description(
            "Bot has been inactive and left the voice channel.",
            "No further action is needed."
          )
        ]

      {:playing, song_payload} ->
        Logger.info(
          "Bot is playing a song in guild #{guild_id}. Updating message with current song."
        )

        song = ElNino.Lavalink.Client.decode_track(song_payload)["info"]

        [
          ElNino.Embeds.queue_embed(ElNino.SongQueue.get_all(guild_id)),
          ElNino.Embeds.current_song_embed(
            song["title"],
            song["uri"],
            song["author"],
            song["artworkUrl"],
            song["length"]
          )
        ]

      {:paused, song_payload} ->
        Logger.info("Bot is paused in guild #{guild_id}. Updating message with current song.")
        song = ElNino.Lavalink.Client.decode_track(song_payload)["info"]

        [
          ElNino.Embeds.queue_embed(ElNino.SongQueue.get_all(guild_id)),
          ElNino.Embeds.current_song_embed(
            song["title"],
            song["uri"],
            song["author"],
            song["artworkUrl"],
            song["length"],
            "Bot is paused."
          )
        ]
    end
  end

  defp ensure_one_message(channel_id) do
    bot_id = Nostrum.Cache.Me.get().id

    case Nostrum.Api.Channel.messages(channel_id, 100) do
      {:ok, []} ->
        Nostrum.Api.Message.create(channel_id, %{
          embeds: [
            ElNino.Embeds.two_liner_author_description(
              "Bot is not connected to a voice channel.",
              "Use the `/play` command to start playing music."
            )
          ]
        })

      {:ok, [%Nostrum.Struct.Message{author: %{id: id}} = message]} when id == bot_id ->
        {:ok, message}

      {:ok, messages} ->
        message_ids = Enum.map(messages, fn %Nostrum.Struct.Message{id: id} -> id end)
        Nostrum.Api.Channel.bulk_delete_messages(channel_id, message_ids)
        ensure_one_message(channel_id)

      {:error, reason} ->
        Logger.error(
          "Error retrieving messages for channel #{channel_id}. Reason: #{inspect(reason)}"
        )

        {:error, reason}
    end
  end

  defp build_components([pause?, resume?, skip?, add?], [pause_style, resume_style, skip_style]) do
    [
      %{
        type: 1,
        components: [
          %{
            type: 2,
            style: pause_style,
            custom_id: "music_pause",
            label: "Pause",
            disabled: pause?
          },
          %{
            type: 2,
            style: resume_style,
            custom_id: "music_resume",
            label: "Resume",
            disabled: resume?
          },
          %{type: 2, style: skip_style, custom_id: "music_skip", label: "Skip", disabled: skip?},
          %{type: 2, style: 1, custom_id: "music_add", label: "Add Song", disabled: add?}
        ]
      }
    ]
  end

  defp disable_components(state) do
    case state do
      {:not_connected, _} -> [true, true, true, false]
      {:connecting, _} -> [true, true, true, false]
      {:waiting, _} -> [true, true, true, false]
      {:playing, _} -> [false, true, false, false]
      {:paused, _} -> [true, false, false, false]
      {:leaving, _} -> [true, true, true, false]
      {:leaving_timeout, _} -> [true, true, true, false]
    end
  end

  defp style_components(_state), do: [2, 2, 2]
end
