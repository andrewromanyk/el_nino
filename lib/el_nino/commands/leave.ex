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

  def handle(%Interaction{guild_id: guild_id} = _interaction) do
    ElNino.SongManager.leave(guild_id)
  end
end
