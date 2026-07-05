defmodule ElNino.Handlers.Voice do
  @moduledoc """
  Accumulates voice state and server updates per guild, dispatching to Lavalink when complete.
  """
  require Logger
  alias Nostrum.Struct.Event.VoiceState
  alias Nostrum.Struct.Event.VoiceServerUpdate

  def handle_event(
        {:VOICE_STATE_UPDATE,
         %VoiceState{
           guild_id: guild_id,
           user_id: user_id,
           channel_id: nil
         }, _ws_state}
      ) do
    if user_id == Nostrum.Cache.Me.get().id do
      Logger.info("VoiceState: Bot has been kicked from the voice channel for Guild #{guild_id}.")
      ElNino.SongManager.disconnected(guild_id)
      ElNino.Response.message_with_embed(
        :ets.lookup(:last_interaction, guild_id) |> List.first() |> elem(1),
        ElNino.Embeds.one_liner_author("Bot has been disconnected from the voice channel.")
      )
    end
  end

  def handle_event(
        {:VOICE_STATE_UPDATE,
         %VoiceState{
           guild_id: guild_id,
           session_id: session_id,
           user_id: user_id,
           channel_id: channel_id
         }, _ws_state}
      ) do
    if user_id == Nostrum.Cache.Me.get().id do
      Logger.info("VoiceState: Bot has joined a voice channel for Guild #{guild_id}.")
      merge_and_check(guild_id, %{session_id: session_id, channel_id: channel_id})
    end
  end

  def handle_event(
        {:VOICE_SERVER_UPDATE,
         %VoiceServerUpdate{guild_id: guild_id, token: token, endpoint: endpoint}, _ws_state}
      ) do
    Logger.info("VoiceServer: Received voice server update for Guild #{guild_id}.")
    merge_and_check(guild_id, %{token: token, endpoint: endpoint})
  end

  defp merge_and_check(guild_id, new_data) do
    updated_state = ElNino.Common.merge_ets(:voice_states, guild_id, new_data)

    attempt_lavalink_dispatch(guild_id, updated_state)
  end

  defp attempt_lavalink_dispatch(guild_id, %{
         session_id: sid,
         token: t,
         endpoint: e,
         channel_id: cid
       })
       when not is_nil(sid) and not is_nil(t) and not is_nil(e) and not is_nil(cid) do
    Logger.info("Voice credentials acquired for Guild #{guild_id}. Dispatching to Lavalink.")

    lavalink_sid = :persistent_term.get(:lavalink_session_id)

    ElNino.Lavalink.Client.update_player(lavalink_sid, guild_id,
      voice: %{
        session_id: sid,
        token: t,
        endpoint: e,
        channel_id: cid
      }
    )

    ElNino.SongManager.connected(guild_id)

    :ets.delete(:voice_states, guild_id)
  end

  defp attempt_lavalink_dispatch(_guild_id, _incomplete_state), do: :ok
end
