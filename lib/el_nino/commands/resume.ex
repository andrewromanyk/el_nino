defmodule ElNino.Commands.Resume do
  @moduledoc """
  Command that resumes currently playing music.
  """

  alias Nostrum.Struct.Interaction
  alias ElNino.Colors

  def name(), do: "resume"

  def definition() do
    %{
      name: name(),
      description: "Resume currently playing music."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case ElNino.SongManager.resume(guild_id) do
      {:ok, _message} ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author("Resumed playback")
        )

      {:error, message} ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author(message, Colors.warn_color())
        )
    end
  end
end
