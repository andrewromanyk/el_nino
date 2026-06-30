defmodule ElNino.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: ElNino.Worker.start_link(arg)
      # {ElNino.Worker, arg}
    ]

    opts = [strategy: :one_for_one, name: ElNino.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
