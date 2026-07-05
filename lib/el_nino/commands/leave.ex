defmodule ElNino.Commands.Leave do
  @moduledoc """
  Leaves the current voice channel and clears the queue.
  """

  alias Nostrum.Struct.Interaction

  def name(), do: "leave"

  def definition() do
    %{
      name: name(),
      description: "Leave the current voice channel and clear the queue."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case ElNino.Common.get_voice_channel_of_bot(guild_id) do
      nil ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("Not in a voice channel."),
          true
        )

      _channel_id ->
        ElNino.SongManager.leave(guild_id)

        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("Left voice channel"),
          true
        )
    end
  end
end
