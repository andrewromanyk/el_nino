defmodule ElNino.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    bot_options = %{
      name: ElNinoBot,
      consumer: ElNino.Consumer,
      intents: [:direct_messages, :guild_messages, :message_content],
      wrapped_token: fn -> System.fetch_env!("DISCORD_TOKEN") end
    }

    children = [
      {Nostrum.Bot, bot_options}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
