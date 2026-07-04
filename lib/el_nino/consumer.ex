defmodule ElNino.Consumer do
  @behaviour Nostrum.Consumer

  require Logger

  alias Nostrum.Struct.Interaction

  @commands [
    ElNino.Commands.Echo,
    ElNino.Commands.Play,
    ElNino.Commands.Pause,
    ElNino.Commands.Resume,
    ElNino.Commands.Leave
  ]

  defp register_command(command), do: register_command(966_052_378_023_444_560, command)

  defp register_command(guild_id, command) do
    case Nostrum.Api.ApplicationCommand.create_guild_command(guild_id, command) do
      {:ok, _} -> IO.puts("Successfully registered " <> command.name <> " command!")
      _ -> IO.puts("Failed to register " <> command.name <> " command!")
    end
  end

  # Registering all slash commands on bot ready event
  # TODO: Redo to register only when needed
  def handle_event({:READY, _, _}) do
    Enum.each(@commands, fn command -> register_command(command.definition()) end)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: "echo"}} = interaction, _ws_state}
      ) do
    ElNino.Commands.Echo.handle(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: "play"}} = interaction, _ws_state}
      ) do
    ElNino.Commands.Play.handle(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: "pause"}} = interaction, _ws_state}
      ) do
    ElNino.Commands.Pause.handle(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: "resume"}} = interaction, _ws_state}
      ) do
    ElNino.Commands.Resume.handle(interaction)
  end

  def handle_event(
        {:INTERACTION_CREATE, %Interaction{data: %{name: "leave"}} = interaction, _ws_state}
      ) do
    ElNino.Commands.Leave.handle(interaction)
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
end
