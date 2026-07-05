defmodule ElNino.Consumer do
  @behaviour Nostrum.Consumer

  @compile {:nowarn_unused_function, [register_command: 1, register_command: 2]}

  require Logger

  alias Nostrum.Struct.Interaction

  @commands [
    ElNino.Commands.Echo,
    ElNino.Commands.Play,
    ElNino.Commands.Pause,
    ElNino.Commands.Resume,
    ElNino.Commands.PlayNext,
    ElNino.Commands.Volume,
    ElNino.Commands.Leave
  ]

  def register_command(command), do: register_command(966_052_378_023_444_560, command)

  def register_command(guild_id, command) do
    case Nostrum.Api.ApplicationCommand.create_guild_command(guild_id, command) do
      {:ok, _} -> IO.puts("Successfully registered " <> command.name <> " command!")
      _ -> IO.puts("Failed to register " <> command.name <> " command!")
    end
  end

  defp register_all_commands_guild(guild_id) do
    case Nostrum.Api.ApplicationCommand.bulk_overwrite_guild_commands(
           guild_id,
           Enum.map(@commands, & &1.definition())
         ) do
      {:ok, _} ->
        IO.puts("Successfully registered all commands for guild #{guild_id}!")

      {:error, %Nostrum.Error.ApiError{response: response}} ->
        IO.puts("Failed to register commands for guild #{guild_id}! Error: #{response}")
    end
  end

  # Registering all slash commands on bot ready event
  # TODO: Redo to register only when needed
  def handle_event({:READY, _, _}) do
    register_all_commands_guild(966_052_378_023_444_560)
  end

  def handle_event({:INTERACTION_CREATE, %Interaction{guild_id: guild_id, channel_id: channel_id} = interaction, _ws_state}) do
    if not is_nil(guild_id) and not is_nil(channel_id) do
      :ets.insert(:last_interaction, {guild_id, channel_id})
    end

    route_command(interaction)
  end

  def handle_event({:VOICE_STATE_UPDATE, _, _} = event) do
    ElNino.Handlers.Voice.handle_event(event)
  end

  def handle_event({:VOICE_SERVER_UPDATE, _, _} = event) do
    ElNino.Handlers.Voice.handle_event(event)
  end

  def handle_event({:VOICE_SPEAKING_UPDATE, payload, _ws_state}) do
    Logger.debug("VOICE SPEAKING UPDATE #{inspect(payload)}")
  end

  def handle_event(_), do: :ok

  # 3. Rename your specific handlers from handle_event/1 to route_command/1
  defp route_command(%Interaction{data: %{name: "echo"}} = interaction) do
    ElNino.Commands.Echo.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "play"}} = interaction) do
    ElNino.Commands.Play.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "pause"}} = interaction) do
    ElNino.Commands.Pause.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "resume"}} = interaction) do
    ElNino.Commands.Resume.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "play_next"}} = interaction) do
    ElNino.Commands.PlayNext.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "volume"}} = interaction) do
    ElNino.Commands.Volume.handle(interaction)
  end

  defp route_command(%Interaction{data: %{name: "leave"}} = interaction) do
    ElNino.Commands.Leave.handle(interaction)
  end

end
