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
    Common.join_voice_chat(interaction)
    ElNino.SongManager.play(url, guild_id)
  end
end
