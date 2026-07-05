defmodule ElNino.Commands.Play do
  @moduledoc """
  Command that plays music in the current voice channel.
  """

  alias ElNino.{Common, Embeds}
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
          name: "url",
          description: "url to the video to play",
          required: true
        }
      ]
    }
  end

  def handle(%Interaction{data: %{options: [%{value: url}]}, guild_id: guild_id} = interaction) do
    Common.join_voice_chat(interaction)

    with {:ok,
          %{
            "encoded" => encoded,
            "info" => %{
              "artworkUrl" => artwork_url,
              "author" => author,
              "title" => title,
              "uri" => uri,
              "length" => length
            }
          }} <- ElNino.Lavalink.Client.load_tracks_best(url),
         {:ok, _} <- ElNino.SongManager.play(encoded, guild_id) do
      ElNino.Response.response_with_embed(
        interaction,
        Embeds.song_added_to_queue(title, uri, author, artwork_url, length)
      )
    else
      {:error, message} ->
        ElNino.Response.response_with_embed(
          interaction,
          Embeds.error("Could not load track", message)
        )
    end
  end
end
