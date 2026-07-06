defmodule ElNino.Commands.Play do
  @moduledoc """
  Command that plays music in the current voice channel.
  """

  require Logger

  alias ElNino.{Embeds, Discord}
  alias Nostrum.Struct.Interaction

  def name(), do: "play"

  def definition() do
    %{
      name: name(),
      description:
        "Play music in the current voice channel or adds it to the queue if one is currently playing.",
      options: [
        %{
          type: 3,
          name: "query",
          description: "Search query or URL to the video to play",
          required: true
        }
      ]
    }
  end

  def handle(%Interaction{data: %{options: [%{value: query}]}, guild_id: guild_id} = interaction) do
    with  true <- Discord.Common.join_voice_chat(interaction),
          {:ok,
          %{
            "encoded" => encoded,
            "info" => %{
              "artworkUrl" => artwork_url,
              "author" => author,
              "title" => title,
              "uri" => uri,
              "length" => length
            }
          }} <- ElNino.Lavalink.Client.load_tracks_best(query),
          {:ok, _} <- ElNino.SongManager.play(encoded, guild_id)
    do
      if not ElNino.Song.Supervisor.pair_exists?(guild_id) do
        Logger.info("SongManager: No manager/queue pair found for guild #{guild_id}. Creating new pair.")
        ElNino.Song.Supervisor.create_manager_queue_pair(guild_id)
      end

      ElNino.Response.response_with_embed(
        interaction,
        Embeds.song_added_to_queue(title, uri, author, artwork_url, length)
      )

    else
      false ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("You must be in a voice channel to use this command.", ElNino.Colors.warn_color())
        )
      {:error, message} ->
        ElNino.Response.response_with_embed(
          interaction,
          Embeds.error("Could not load track", message)
        )
    end
  end
end
