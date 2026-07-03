defmodule ElNino.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    bot_options = %{
      name: ElNinoBot,
      consumer: ElNino.Consumer,
      intents: [
        :guilds,
        :guild_voice_states,
        :guild_messages,
        :message_content
      ],
      wrapped_token: fn -> System.fetch_env!("DISCORD_TOKEN") end
    }

    children = [
      {Nostrum.Bot, bot_options},
      {ElNino.SongQueue, []},
      {ElNino.Lavalink.Supervisor, []}
    ]

    :ets.new(:voice_states, [:set, :public, :named_table])
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
