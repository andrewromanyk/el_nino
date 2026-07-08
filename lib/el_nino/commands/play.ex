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
    with _            <- ElNino.Song.Supervisor.ensure_pair_exists(guild_id),
         true         <- Discord.Common.join_voice_chat(interaction),
         load_tracks  <- ElNino.Lavalink.Client.load_tracks_best(query) do
      case load_tracks do
        {:ok, :track,
          %{
            "encoded" => encoded,
            "info" => %{
              "artworkUrl" => artwork_url,
              "author" => author,
              "title" => title,
              "uri" => uri,
              "length" => length
            }
          }
        }  ->
          ElNino.SongManager.play(encoded, guild_id)
          ElNino.Response.response_with_embed(
            interaction,
            Embeds.song_added_to_queue(title, uri, author, artwork_url, length)
          )

        {:ok, :playlist, %{"info" => %{"name" => name}, "tracks" => [ %{"info" => %{"artworkUrl" => artwork_url}} | _] = playlist}} ->

          ElNino.SongManager.play_list(playlist |> Enum.map(&(&1["encoded"])), guild_id)

          ElNino.Response.response_with_embed(
            interaction,
            Embeds.playlist_added_to_queue(name, artwork_url, query, playlist |> length() |> Integer.to_string())
          )
      end
    else
      false ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author(
            "You must be in a voice channel to use this command.",
            ElNino.Colors.warn_color()
          )
        )

      {:error, message} ->
        ElNino.Response.response_with_embed(
          interaction,
          Embeds.error("Could not load track", message)
        )
    end
  end
end
