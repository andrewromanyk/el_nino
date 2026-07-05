defmodule ElNino.Lavalink.Supervisor do
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {ElNino.Lavalink.Socket,
       bot_id: 1_521_137_252_518_985_788,
       client_name: "ElNino/1.0",
       authorization: "youshallnotpass",
       url: "ws://localhost:2333/v4/websocket"}
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 10, max_seconds: 5)
  end
end
