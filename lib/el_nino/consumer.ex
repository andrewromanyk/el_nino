defmodule ElNino.Consumer do
  @behaviour Nostrum.Consumer

  def register_command(guild_id, command) do
    case Nostrum.Api.ApplicationCommand.create_guild_command(guild_id, command) do
      {:ok, _} -> IO.puts("Successfully registered " <> command.name <> " command!")
      _ -> IO.puts("Failed to register " <> command.name <> " command!")
    end
  end

  def register_command(command), do: register_command(966052378023444560, command)

  def handle_event({:READY, _, _}) do
    register_command(ElNino.DefCommands.echo())
    register_command(ElNino.DefCommands.join())
    register_command(ElNino.DefCommands.play_music())
  end

  def handle_event({:INTERACTION_CREATE, interaction, _ws_state}) do
    case interaction.data.name do
      "echo" -> handle_echo(interaction)
      "join" -> handle_join(interaction)
      "play_music" -> handle_play_music(interaction)
    end
  end

  def handle_event(_), do: :ok

  def handle_echo(interaction) do
    response = %{
      type: 4,  # ChannelMessageWithSource
      data: %{
        content: (interaction.data.options |> Enum.at(0)).value
      }
    }
    Nostrum.Api.Interaction.create_response(interaction, response)
  end

  def handle_join(interaction) do
    Nostrum.Voice.join_channel(interaction.guild_id, get_voice_channel_of_interaction(interaction))
  end

  def handle_play_music(interaction) do
    Nostrum.Voice.play(
      interaction.guild_id,
      (interaction.data.options |> Enum.at(0)).value,
      :ytdl)
  end

  def get_voice_channel_of_interaction(%{guild_id: guild_id, user: %{id: user_id}}) do
    case Nostrum.Cache.GuildCache.get(guild_id) do
      {:ok, guild} ->
        guild
        |> Map.get(:voice_states, [])
        |> Enum.find(%{}, fn v -> v.user_id == user_id end)
        |> Map.get(:channel_id)

      {:error, reason} ->
        IO.puts(reason)
        nil
    end
  end

end
