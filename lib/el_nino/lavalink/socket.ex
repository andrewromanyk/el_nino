defmodule ElNino.Lavalink.Socket do
  @moduledoc """
  A module that handles the connection to the Lavalink server.
  """

  use WebSockex
  require Logger

  def start_link(opts) do
    bot_id = Keyword.fetch!(opts, :bot_id)
    client_name = Keyword.get(opts, :client_name)
    authorization = Keyword.get(opts, :authorization)
    url = Keyword.get(opts, :url)

    headers = [
      {"Authorization", authorization},
      {"User-Id", to_string(bot_id)},
      {"Client-Name", client_name}
    ]

    WebSockex.start_link(url, __MODULE__, %{session_id: nil},
      extra_headers: headers,
      name: __MODULE__,
      handle_initial_conn_failure: true
    )
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to Lavalink Node")
    {:ok, state}
  end

  @impl true
  def handle_disconnect(connection_status_map, state) do
    Logger.warning("Disconnected from Lavalink: #{inspect(connection_status_map)}")
    Process.sleep(1500)
    {:reconnect, state}
  end

  @impl true
  def handle_frame({:text, msg}, state) do
    case Jason.decode!(msg) do
      %{"op" => "ready", "sessionId" => session_id} ->
        Logger.info("Lavalink Session Acquired: #{session_id}")
        :persistent_term.put(:lavalink_session_id, session_id)
        {:ok, %{state | session_id: session_id}}

      %{
        "op" => "event",
        "type" => "TrackEndEvent",
        "guildId" => guild_id,
        "reason" => reason
      } = _event ->
        Logger.info("Track ended in guild #{guild_id}")

        case reason do
          "finished" ->
            Logger.info(
              "Track finished playing in guild #{guild_id}. Attempting to play next song."
            )

            ElNino.SongManager.play_next(guild_id)

          "replaced" ->
            Logger.info("Track was replaced in guild #{guild_id}.")

          _ ->
            Logger.info("Track ended for unknown reason in guild #{guild_id}: #{reason}")
            ElNino.SongManager.play_next(guild_id)
        end

        {:ok, state}

      %{
        "op" => "event",
        "type" => "TrackExceptionEvent",
        "guildId" => guild_id,
        "track" => track,
        "exception" => exception
      } = _event ->
        Logger.info(
          "Track exception in guild #{guild_id}. Track: #{track}. Exception: #{inspect(exception)}"
        )

        {:ok, state}

      %{
        "op" => "event",
        "type" => "TrackStuckEvent",
        "guildId" => guild_id,
        "thresholdMs" => threshold_ms
      } = _event ->
        Logger.info("Track stuck in guild #{guild_id}. Threshold: #{threshold_ms}.")
        {:ok, state}

      %{
        "op" => "event",
        "type" => "WebSocketClosedEvent",
        "guildId" => guild_id,
        "code" => code,
        "reason" => reason,
        "byRemote" => by_remote
      } = _event ->
        Logger.info(
          "WebSocket closed in guild #{guild_id}. Code: #{code}. Reason: <#{reason}>. By Remote: #{by_remote}"
        )

        {:ok, state}

      _ ->
        {:ok, state}
    end
  end
end
