defmodule ElNino.Discord.Common do
  @moduledoc """
  Common functions for interacting with Discord.
  """

  require Logger

  alias Nostrum.Struct.{Guild, Interaction}
  alias Nostrum.Cache.GuildCache
  alias Nostrum.Api
  alias Nostrum.Struct.Guild

  def join_voice_chat(%Interaction{guild_id: guild_id} = interaction) do
    Logger.info("Joining voice chat for guild #{guild_id}.")
    Nostrum.Api.Self.update_voice_state(guild_id, get_voice_channel_of_interaction(interaction))
  end

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

  def get_last_channel_of_interaction(guild_id) do
    case :ets.lookup(:last_interaction, guild_id) do
      [{^guild_id, channel_id}] -> channel_id
      [] -> nil
    end
  end

  def if_user_can_request_song_command(%Interaction{guild_id: guild_id, user: %{id: user_id}} = interaction, do: can_block) do
    case user_can_request_song_command?(guild_id, user_id) do
      :can -> can_block.()
      :not_in_vc -> ElNino.Response.response_with_embed(
                      interaction,
                      ElNino.Embeds.one_liner_author("You must be in a voice channel to use this command."),
                      true
                    )
      :not_in_same_vc -> ElNino.Response.response_with_embed(
                          interaction,
                          ElNino.Embeds.one_liner_author("You must be in the same voice channel as the bot to use this command."),
                          true
                        )
    end
  end

  def user_can_request_song_command?(guild_id, user_id) do
    user_channel_id = get_voice_channel_of_interaction(guild_id, user_id)
    bot_channel_id = get_voice_channel_of_bot(guild_id)
    # if the user is not in voice - can't; if in voice, then must be in the same channel as the bot
    cond do
      is_nil(user_channel_id) -> :not_in_vc

      user_channel_id == bot_channel_id or is_nil(bot_channel_id) -> :can

      true -> :not_in_same_vc
    end
  end

  def channel_exists?(guild_id, channel_id) do
    case Nostrum.Api.Channel.get(channel_id) do
      {:ok, %Nostrum.Struct.Channel{guild_id: ^guild_id}} -> true
      _ -> false
    end
  end

  def administrator?(guild_id, user_id) do
    with {:ok, guild} <- fetch_guild(guild_id),
         {:ok, member} <- fetch_member(guild_id, user_id) do

      if guild.owner_id == user_id do
        true
      else
        permissions = Guild.Member.guild_permissions(member, guild)
        Enum.member?(permissions, :administrator)
      end
    else
      _error -> false
    end
  end

  defp fetch_guild(guild_id) do
    case GuildCache.get(guild_id) do
      {:ok, guild} -> {:ok, guild}
      {:error, _reason} -> {:error, :guild_not_found}
    end
  end

  defp fetch_member(guild_id, user_id) do
    case Api.Guild.member(guild_id, user_id) do
      {:ok, member} -> {:ok, member}
      {:error, _reason} -> {:error, :member_not_found}
    end
  end
end
