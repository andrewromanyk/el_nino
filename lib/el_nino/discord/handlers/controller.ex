defmodule ElNino.Handlers.Controller do
  @moduledoc """
  Handles the controller events from Discord.
  """

  alias ElNino.Discord

  def handle_event({:INTERACTION_CREATE, %Nostrum.Struct.Interaction{type: 3, data: data, guild_id: guild_id} = interaction, _ws_state}) do
    case data.custom_id do
      "music_pause" ->
        ElNino.SongManager.pause(guild_id)

      "music_resume" ->
        ElNino.SongManager.resume(guild_id)

      "music_skip" ->
        ElNino.SongManager.play_next(guild_id)

      "music_add" ->
        Nostrum.Api.Interaction.create_response(interaction, %{
          type: 9,
          data: %{
            custom_id: "search_modal",
            title: "Add a Song",
            components: [
              %{
                type: 1, # Action Row
                components: [
                  %{
                    type: 4, # Text Input
                    custom_id: "song_query",
                    label: "Search query or URL",
                    style: 1, # Short text
                    min_length: 1,
                    max_length: 200,
                    required: true
                  }
                ]
              }
            ]
          }
        })
      _ ->
        :ignore
    end

    # You MUST acknowledge the interaction.
    # Type 6 (DeferredUpdateMessage) tells Discord "I received the click, do nothing to the message right now."
    # Your SongManager handles the actual message update asynchronously via handle_state.
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 6
    })
  end

  def handle_event({:INTERACTION_CREATE,
    %Nostrum.Struct.Interaction{type: 5,
      data:
        %{
          custom_id: "search_modal",
          components: [%Nostrum.Struct.Message.Component{components: [%Nostrum.Struct.Message.Component{custom_id: "song_query", value: query}]}]
        },
      guild_id: guild_id} = interaction, _ws_state}) do
    Nostrum.Api.Interaction.create_response(interaction, %{
      type: 6
    })

    with(
      # if not in a voice channel, stop everything
      channel_id when not is_nil(channel_id) <-
        Discord.Common.get_voice_channel_of_interaction(interaction),
      # we must have a manager-queue pair active before anything happens
      _ <- ElNino.Song.Supervisor.ensure_pair_exists(guild_id),
      # sends update state, if we don't have manager-queue pair later actions will fail
      :ok <- Discord.Common.join_voice_chat(interaction),
      # relatively stateless, but if done first and something breaks - it is useless
      {:ok, _, _} = load_tracks <- ElNino.Lavalink.Client.load_tracks_best(query)
    ) do
      case load_tracks do
        {:ok, :track, %{"encoded" => encoded}} ->

          ElNino.SongManager.play(encoded, guild_id)

        {:ok, :playlist, %{"tracks" =>  playlist}} ->
          ElNino.SongManager.play_list(playlist |> Enum.map(& &1["encoded"]), guild_id)
      end
    end
  end
end
