defmodule ElNino.Lavalink.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {ElNino.Lavalink.Socket,
       bot_id: String.to_integer(System.fetch_env!("BOT_ID")),
       client_name: System.get_env("CLIENT_NAME", "ElNino/1.0"),
       authorization: System.get_env("LAVALINK_PASSWORD", "youshallnotpass"),
       url: "ws://" <> System.get_env("LAVALINK_ENDPOINT") <> "/v4/websocket"}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 5)
  end
end
