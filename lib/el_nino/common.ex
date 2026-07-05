defmodule ElNino.Common do
  @moduledoc """
  Common functions for the ElNino bot.
  """
  require Logger

  alias Nostrum.Struct.Interaction

  def get_voice_channel_of_interaction(%{guild_id: guild_id, user: %{id: user_id}}) do
    with  {:ok, guild} <- Nostrum.Cache.GuildCache.get(guild_id),
          %{} = voice_state <- Enum.find(guild.voice_states, fn v -> v.user_id == user_id end) do
      voice_state.channel_id
    else
      {:error, reason} ->
        Logger.error("Failed to get guild #{guild_id} from cache: #{inspect(reason)}")
        nil
    end
  end

  def join_voice_chat(%Interaction{guild_id: guild_id} = interaction) do
    Nostrum.Api.Self.update_voice_state(guild_id, get_voice_channel_of_interaction(interaction))
  end
end
