defmodule ElNino.Commands.Pause do
  @moduledoc """
  Command that pauses currently playing music.
  """

  alias Nostrum.Struct.Interaction

  def name(), do: "pause"

  def definition() do
    %{
      name: name(),
      description: "Pause currently playing music."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case ElNino.SongManager.pause(guild_id) do
      {:ok, message} ->
        ElNino.Response.response_with_embed(interaction, ElNino.Embeds.info("Paused", message))

      {:error, message} ->
        ElNino.Response.response_with_embed(interaction, ElNino.Embeds.info("Cannot pause", message))
    end
  end
end
