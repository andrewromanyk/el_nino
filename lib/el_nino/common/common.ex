defmodule ElNino.Common do
  @moduledoc """
  Common functions for the ElNino bot.
  """
  require Logger

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

  def via_registry(registry, key) do
    {:via, Registry, {registry, key}}
  end

  @spec via_guild_manager_registry(any()) :: {:via, Registry, {any(), any()}}
  def via_guild_manager_registry(guild_id) do
    via_registry(GuildSongManagerRegistry, guild_id)
  end

  def via_guild_queue_registry(guild_id) do
    via_registry(GuildSongQueueRegistry, guild_id)
  end
end
