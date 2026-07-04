defmodule ElNino.Lavalink.Socket do
  @moduledoc """
  A module that handles the connection to the Lavalink server.
  """

  use WebSockex
  require Logger

  def start_link(opts) do
    bot_id = Keyword.fetch!(opts, :bot_id)
    url = "ws://localhost:2333/v4/websocket"

    headers = [
      {"Authorization", "youshallnotpass"},
      {"User-Id", to_string(bot_id)},
      {"Client-Name", "ElNino/1.0"}
    ]

    WebSockex.start_link(url, __MODULE__, %{session_id: nil},
      extra_headers: headers,
      name: __MODULE__
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
    payload = Jason.decode!(msg)

    case payload do
      %{"op" => "ready", "sessionId" => session_id} ->
        Logger.info("Lavalink Session Acquired: #{session_id}")
        :persistent_term.put(:lavalink_session_id, session_id)
        {:ok, %{state | session_id: session_id}}

      %{"op" => "event", "type" => "TrackEndEvent", "guildId" => guild_id} = _event ->
        Logger.info("Track ended in guild #{guild_id}")
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end
end
