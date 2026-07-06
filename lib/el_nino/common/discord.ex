defmodule ElNino.Discord.Common do
  @moduledoc """
  Common functions for interacting with Discord.
  """

  require Logger

  alias Nostrum.Struct.Interaction

  def get_voice_channel_of_bot(guild_id),
    do: get_voice_channel_of_interaction(guild_id, Nostrum.Cache.Me.get().id)

  def get_voice_channel_of_interaction(%{guild_id: guild_id, user: %{id: user_id}}),
    do: get_voice_channel_of_interaction(guild_id, user_id)

  def get_voice_channel_of_interaction(guild_id, user_id) do
    with {:ok, guild} <- Nostrum.Cache.GuildCache.get(guild_id),
         %{} = voice_state <- Enum.find(guild.voice_states, fn v -> v.user_id == user_id end) do
      voice_state.channel_id
    else
      {:error, reason} ->
        Logger.error("Failed to get guild #{guild_id} from cache: #{inspect(reason)}")
        nil

      nil ->
        Logger.info("User #{user_id} is not in a voice channel in guild #{guild_id}.")
        nil
    end
  end

  def join_voice_chat(%Interaction{guild_id: guild_id} = interaction) do
    Logger.info("Joining voice chat for guild #{guild_id}.")

    case get_voice_channel_of_interaction(interaction) do
      nil -> false

      channel_id ->
        Nostrum.Api.Self.update_voice_state(guild_id, channel_id)
        true
    end
  end
end
