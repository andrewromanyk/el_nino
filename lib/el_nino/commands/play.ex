defmodule ElNino.Commands.Play do
  @moduledoc """
  Command that plays music in the current voice channel.
  """

  alias ElNino.Common
  alias Nostrum.Struct.{Interaction, Embed}
  alias Nostrum.Api

  def name(), do: "play"

  def definition() do
    %{
      name: name(),
      description: "Play music in the current voice channel.",
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

    track =
      case ElNino.Lavalink.Client.load_tracks(url)["data"] do
        nil -> nil
        data -> data |> Enum.at(0)
      end

    with %{
           "encoded" => encoded,
           "info" => %{
             "artworkUrl" => artwork_url,
             "author" => author,
             "title" => title,
             "uri" => uri
           }
         } <- track do
      case ElNino.SongManager.play(encoded, guild_id) do
        {:ok, _} ->
          Api.Interaction.create_response(interaction.id, interaction.token, %{
            type: 4,
            data: %{
              embeds: [
                %Embed{}
                  |> Embed.put_author("Added track to queue", nil, nil)
                  |> Embed.put_title(title)
                  |> Embed.put_url(uri)
                  |> Embed.put_field("Author", author)
                  |> Embed.put_color(6036244)
                  |> Embed.put_thumbnail(artwork_url)
              ]
            }
          })

        {:error, message} ->
          Api.Interaction.create_response(interaction.id, interaction.token, %{
            type: 4,
            data: %{
              embeds: [
                %Embed{
                  title: "Error",
                  description: message,
                  color: 6_036_244
                }
              ]
            }
          })
      end
    else
      {:error, _} ->
        Api.Interaction.create_response(interaction.id, interaction.token, %{
          type: 4,
          data: %{
            embeds: [
              %Embed{
                title: "Error",
                description: "Could not find any tracks for the given URL or search query.",
                color: 6_036_244
              }
            ]
          }
        })
    end
  end
end
