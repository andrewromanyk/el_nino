defmodule ElNino.Commands.Play do
  @moduledoc """
  Command that plays music in the current voice channel.
  """

  alias ElNino.Common
  alias Nostrum.Struct.Interaction

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
    ElNino.SongQueue.push(url)

    Common.join_voice_chat(interaction)
    Nostrum.Voice.play(guild_id, url, :ytdl)

    response = %{
      type: 4,
      data: %{
        content: "Playing music from #{url}"
      }
    }

    Nostrum.Api.Interaction.create_response(interaction, response)
  end
end
