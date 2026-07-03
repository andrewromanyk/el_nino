defmodule ElNino.Common do
  @moduledoc """
  Common functions for the ElNino bot.
  """

  alias Nostrum.Struct.Interaction

  def get_voice_channel_of_interaction(%{guild_id: guild_id, user: %{id: user_id}}) do
    case Nostrum.Cache.GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild
        |> Map.get(:voice_states, [])
        |> Enum.find(%{}, fn v -> v.user_id == user_id end)
        |> Map.get(:channel_id)

      {:error, reason} ->
        IO.puts(reason)
        nil
    end
  end

  def join_voice_chat(%Interaction{guild_id: guild_id} = interaction),
    do: Nostrum.Voice.join_channel(guild_id, get_voice_channel_of_interaction(interaction))
end
