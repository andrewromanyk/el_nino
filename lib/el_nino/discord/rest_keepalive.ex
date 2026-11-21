defmodule ElNino.Discord.RestKeepalive do
  @moduledoc """
  Periodically sends a lightweight REST request to Discord and refreshes the bot user cache.

  Cloud services and NAT gateways (for example Azure NAT Gateway / Load Balancer) silently
  drop idle outbound TCP connections after a timeout (typically 4 minutes in Azure).
  Because Nostrum's REST API client (:gun) does not configure TCP socket keepalives or idle
  connection recycling, an idle REST connection becomes a half-open / dead socket. Subsequent
  requests (such as responding to button clicks or slash commands after a period of inactivity)
  stall waiting for TCP retransmission timeouts.

  Running this request every 2 minutes keeps the outbound REST connection active through
  cloud NAT state tables and ensures the bot's user caches (`Nostrum.Cache.Me` and
  `Nostrum.Cache.UserCache`) stay freshly updated.
  """

  use GenServer
  require Logger

  @interval :timer.minutes(2)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    schedule_next()
    {:ok, %{}}
  end

  @impl true
  def handle_info(:refresh_cache, state) do
    Nostrum.Bot.with_bot(ElNinoBot, fn ->
      case Nostrum.Api.Self.get() do
        {:ok, user} ->
          Nostrum.Cache.Me.put(user)

        {:error, reason} ->
          Logger.warning("RestKeepalive: failed to refresh bot user cache: #{inspect(reason)}")
      end
    end)

    schedule_next()
    {:noreply, state}
  end

  defp schedule_next do
    Process.send_after(self(), :refresh_cache, @interval)
  end
end
