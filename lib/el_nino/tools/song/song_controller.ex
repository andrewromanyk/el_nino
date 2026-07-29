defmodule ElNino.SongController do
  @moduledoc """
  Controller for handling a separate song controller. Bot creates and delegates a separate channel for this.
  """

  require Logger

  def handle_state(guild_id, state) do
    case ElNino.ChannelStore.get(guild_id) do
      {:ok, channel_id} ->
        #get the message from the channel and update it with the current state
        {:ok, %Nostrum.Struct.Message{id: id}} = ensure_one_message(channel_id)
        Logger.info("Retrieved message #{id} from channel #{channel_id} for guild #{guild_id}. Updating message with current state.")
        {:ok, _} = Nostrum.Api.Message.edit(channel_id, id, embeds:
          case state do
            {:not_connected, _} ->
              [ElNino.Embeds.two_liner_author_description("Bot is not connected to a voice channel.", "Use the `/play` command to start playing music.")]

            {:connecting, _} ->
              [ElNino.Embeds.two_liner_author_description("Bot is connecting to a voice channel.", "Please wait while the bot connects.")]

            {:waiting, _} ->
              [ElNino.Embeds.two_liner_author_description("Bot is waiting for a song to be added to the queue.", "Please add a song using the `/play` command.")]

            {:playing, song} ->
              Logger.info("Bot is playing a song in guild #{guild_id}. Updating message with current song.")
              song = ElNino.Lavalink.Client.decode_track(song)["info"]
              [ElNino.Embeds.queue_embed(ElNino.SongQueue.get_all(guild_id)), ElNino.Embeds.current_song_embed(song["title"], song["uri"], song["author"], song["artworkUrl"], song["length"])]

            {:paused, song} ->
              Logger.info("Bot is paused in guild #{guild_id}. Updating message with current song.")
              song = ElNino.Lavalink.Client.decode_track(song)["info"]
              [ElNino.Embeds.queue_embed(ElNino.SongQueue.get_all(guild_id)), ElNino.Embeds.current_song_embed(song["title"], song["uri"], song["author"], song["artworkUrl"], song["length"], "Bot is paused.")]
          end,
        content: "",
        components: build_components(disable_components(state), style_components(state))
        )

      {:error, reason} ->
        Logger.error("Error retrieving manager channel for guild #{guild_id}. Reason: #{inspect(reason)}")

      :not_found ->  # guild might have no manager channel yet, so we do nothing
        Logger.info("No manager channel found for guild #{guild_id}")
    end
  end

  defp ensure_one_message(channel_id) do
    # continuously query 100 messages and delete them until there is no messages and create a new one
    bot_id = Nostrum.Cache.Me.get().id
    case Nostrum.Api.Channel.messages(channel_id, 100) do
      {:ok, []} ->
        Nostrum.Api.Message.create(channel_id, "Placeholder message for the manager channel. This channel is used to manage the bot's music playback.")

      # when one message and is by the bot - return it
      {:ok, [%Nostrum.Struct.Message{author: %{id: id}} = message]} when id == bot_id ->
        {:ok, message}

      {:ok, messages} ->
        message_ids = Enum.map(messages, fn %Nostrum.Struct.Message{id: id} -> id end)
        Nostrum.Api.Channel.bulk_delete_messages(channel_id, message_ids)
        ensure_one_message(channel_id)

      {:error, reason} ->
        Logger.error("Error retrieving messages for channel #{channel_id}. Reason: #{inspect(reason)}")
    end
  end

  defp build_components([pause?, resume?, skip?], [pause_style, resume_style, skip_style]) do
    [
      %{
        type: 1, # Action Row
        components: [
          %{
            type: 2, # Button
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
          %{
            type: 2,
            style: skip_style,
            custom_id: "music_skip",
            label: "Skip",
            disabled: skip?
          },
          %{
            type: 2,
            style: 1, # Primary
            custom_id: "music_add",
            label: "Add Song",
            disabled: false
          }
        ]
      }
    ]
  end

  defp disable_components(state) do
    case state do
      {:not_connected, _} -> [true, true, true]
      {:connecting, _} -> [true, true, true]
      {:waiting, _} -> [true, true, true]
      {:playing, _} -> [false, true, false]
      {:paused, _} -> [true, false, false]
    end
  end

  defp style_components(state) do
    case state do
      {:not_connected, _} -> [2, 2, 2]
      {:connecting, _} -> [2, 2, 2]
      {:waiting, _} -> [2, 2, 2]
      {:playing, _} -> [2, 2, 2]
      {:paused, _} -> [2, 2, 2]
    end
  end
end
