defmodule ElNino.Commands.Resume do
  @moduledoc """
  Command that resumes currently playing music.
  """

  alias Nostrum.Struct.Interaction

  def name(), do: "resume"

  def definition() do
    %{
      name: name(),
      description: "Resume currently playing music."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = _interaction) do
    ElNino.SongManager.resume(guild_id)
  end
end
