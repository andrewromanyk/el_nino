defmodule ElNino.Commands.Pause do
  @moduledoc """
  Command that pauses currently playing music.
  """

  alias Nostrum.Struct.Interaction
  alias ElNino.Colors

  def name(), do: "pause"

  def definition() do
    %{
      name: name(),
      description: "Pause currently playing music."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case ElNino.SongManager.pause(guild_id) do
      {:ok, _message} ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("Paused playback")
        )

      {:error, message} ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("Cannot pause: #{message}", Colors.error_color())
        )
    end
  end
end
