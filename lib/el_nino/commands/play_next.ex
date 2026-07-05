defmodule ElNino.Commands.PlayNext do
  @moduledoc """
  Command that plays the next song in the queue.
  """

  alias ElNino.Common
  alias Nostrum.Struct.{Interaction, Embed}
  alias Nostrum.Api

  def name(), do: "play_next"

  def definition() do
    %{
      name: name(),
      description: "Play the next song in the queue.",
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case Common.get_voice_channel_of_interaction(interaction) do
      nil ->
        Api.Interaction.create_response(interaction.id, interaction.token, %{
          type: 4,
          data: %{
            embeds: [
              %Embed{
                title: "Error",
                description: "You must be in a voice channel to use this command.",
                color: 6_036_244
              }
            ]
          }
        })

      _channel_id ->
        case ElNino.SongManager.play_next(guild_id) do
          {:ok, message} ->
            Api.Interaction.create_response(interaction.id, interaction.token, %{
              type: 4,
              data: %{
                embeds: [
                  %Embed{
                    title: "Success",
                    description: message,
                    color: 6_036_244
                  }
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
    end
  end
end
