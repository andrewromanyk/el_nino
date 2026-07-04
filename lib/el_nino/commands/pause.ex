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

  def handle(%Interaction{guild_id: guild_id} = _interaction) do
    ElNino.SongManager.pause(guild_id)
  end
end
