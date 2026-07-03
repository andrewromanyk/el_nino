defmodule ElNino.Commands.Pause do
  @moduledoc """
  Command that pauses currently playing music.
  """

  alias ElNino.Common
  alias Nostrum.Struct.Interaction

  def name(), do: "pause"

  def definition() do
    %{
      name: name(),
      description: "Pause currently playing music."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    Common.join_voice_chat(interaction)
    Nostrum.Voice.pause(guild_id)

    response = %{
      type: 4,
      data: %{
        content: "Paused music."
      }
    }

    Nostrum.Api.Interaction.create_response(interaction, response)
  end
end
