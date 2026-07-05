defmodule ElNino.Common do
  @moduledoc """
  Common functions for the ElNino bot.
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
      nil ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.error("Error", "You must be in a voice channel to use this command.")
        )

      channel_id ->
        Nostrum.Api.Self.update_voice_state(guild_id, channel_id)
    end
  end

  def ms_to_str(ms) when is_integer(ms) and ms >= 0 do
    total_seconds = div(ms, 1000)
    hours = div(total_seconds, 3600)
    minutes = div(rem(total_seconds, 3600), 60)
    seconds = rem(total_seconds, 60)

    cond do
      hours > 0 -> "#{hours}:#{pad(minutes)}:#{pad(seconds)}"
      minutes > 0 -> "#{minutes}:#{pad(seconds)}"
      true -> "0:#{pad(seconds)}"
    end
  end

  defp pad(n) when n < 10, do: "0#{n}"
  defp pad(n), do: "#{n}"

  def merge_ets(table, guild_id, new_data) do
    current_state =
      case :ets.lookup(table, guild_id) do
        [{^guild_id, state}] -> state
        [] -> %{}
      end

    updated_state = Map.merge(current_state, new_data)

    :ets.insert(table, {guild_id, updated_state})

    updated_state
  end
end
