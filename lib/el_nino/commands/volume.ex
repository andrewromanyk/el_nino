defmodule ElNino.Commands.Volume do
  @moduledoc """
  Command that sets the volume for the currently playing music.
  """

  alias Nostrum.Struct.Interaction

  def name(), do: "volume"

  def definition() do
    %{
      name: name(),
      description: "Set the volume for the currently playing music.",
      options: [
        %{
          type: 4,
          name: "volume",
          description: "Volume level in percent (0-100)",
          required: true,
          min_value: 0,
          max_value: 100
        }
      ]
    }
  end

  def handle(%Interaction{data: %{options: [%{value: volume}]}, guild_id: guild_id} = interaction) do
    if ElNino.Discord.Common.administrator?(guild_id, interaction.user.id) do
      ElNino.Discord.Common.if_user_can_request_song_command(interaction, do: fn ->
      ElNino.SongManager.volume(volume, guild_id)

      ElNino.Response.response_with_embed(
        interaction,
        ElNino.Embeds.one_liner_author("Volume set to #{volume}%")
      )
      end)
    else
      ElNino.Response.response_with_embed(
        interaction,
        ElNino.Embeds.one_liner_author("You must be an administrator to use this command."),
        true
      )
    end
  end
end
