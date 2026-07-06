defmodule ElNino.Lavalink.Client do
  require Logger

  @headers [{"Authorization", "youshallnotpass"}]
  @header_json [{"Content-Type", "application/json"}]
  @base_url "http://localhost:2333/v4"
  @prefixes ["", "ytmsearch:", "ytsearch:", "scsearch:"]

  def load_tracks_best(query) do
    case Enum.find_value(@prefixes, fn prefix -> load_tracks_first(query, prefix) end) do
      nil ->
        Logger.info("Lavalink: No tracks found for query #{query} with any prefix.")
        {:error, "No tracks found for the given query."}

      # useless case for now, will help when we add functionality for playlists
      playlist when is_list(playlist) ->
        Logger.info(
          "Lavalink: Found playlist with #{length(playlist)} tracks for query #{query}."
        )

        {:ok, playlist}

      track ->
        Logger.info("Lavalink: Found track #{track["info"]["title"]} for query #{query}.")
        {:ok, track}
    end
  end

  def load_tracks_first(query, prefix \\ "") do
    case load_tracks(query, prefix) do
      %{"loadType" => "track", "data" => track} -> track
      # search results return a list of tracks, we take the first one
      %{"loadType" => "search", "data" => [track | _]} -> track
      # unlike search, user implied to add the whole playlist (as specified in the url)
      %{"loadType" => "playlist", "data" => [track | _] = _playlist} -> track
      # TODO: handle playlists
      _ -> nil
    end
  end

  def load_tracks(query, prefix \\ "") do
    Req.get!("#{@base_url}/loadtracks",
      headers: @headers,
      params: [identifier: "#{prefix}#{query}"]
    )
    |> Map.get(:body)
  end

  def update_player(session_id, guild_id,
        voice: %{
          token: token,
          endpoint: endpoint,
          session_id: discord_session_id,
          channel_id: channel_id
        }
      ) do
    Req.patch!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers ++ @header_json,
      params: [noReplace: true],
      json: %{
        voice: %{
          token: token,
          endpoint: endpoint,
          sessionId: discord_session_id,
          channelId: to_string(channel_id)
        }
      }
    )
  end

  def update_player(session_id, guild_id, encoded_track: encoded_track) do
    Req.patch!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers ++ @header_json,
      params: [noReplace: false],
      json: %{
        track: %{
          encoded: encoded_track
        }
      }
    )
  end

  def update_player(session_id, guild_id, paused: paused) do
    Req.patch!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers ++ @header_json,
      params: [noReplace: false],
      json: %{
        paused: paused
      }
    )
  end

  def update_player(session_id, guild_id, volume: volume)
      when is_number(volume) and volume >= 0 and volume <= 1000 do
    Req.patch!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers ++ @header_json,
      params: [noReplace: false],
      json: %{
        volume: volume
      }
    )
  end

  def destroy_player(session_id, guild_id) do
    Req.delete!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers
    )
  end

  def get_players(session_id) do
    Req.get!("#{@base_url}/sessions/#{session_id}/players",
      headers: @headers
    )
  end
end
