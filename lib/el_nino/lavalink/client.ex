defmodule ElNino.Lavalink.Client do
  require Logger

  @headers [{"Authorization", "youshallnotpass"}]
  @header_json [{"Content-Type", "application/json"}]
  @base_url "http://localhost:2333/v4"

  def load_tracks("scsearch:" <> query) do
    Req.get!("#{@base_url}/loadtracks",
      headers: @headers,
      params: [identifier: "scsearch:#{query}"]
    )
    |> Map.get(:body)
    |> Map.get("data")
    |> Enum.at(0)
    |> Map.get("encoded")
  end

  def load_tracks(query) do
    Req.get!("#{@base_url}/loadtracks",
      headers: @headers,
      params: [identifier: "ytsearch:#{query}"]
    )
    |> Map.get(:body)
    |> Map.get("data")
    |> Enum.at(0)
    |> Map.get("encoded")
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
        encodedTrack: encoded_track
      }
    )
  end

  def destroy_player(session_id, guild_id) do
    Req.delete!("#{@base_url}/sessions/#{session_id}/players/#{guild_id}",
      headers: @headers
    )
  end
end
