defmodule ElNino.Consumer do
  @behaviour Nostrum.Consumer

  @servers [966_052_378_023_444_560, 1_399_293_262_249_852_989]

  require Logger

  alias Nostrum.Struct.Interaction
  alias Nostrum.Api.ApplicationCommand

  @commands [
    ElNino.Commands.Echo,
    ElNino.Commands.Play,
    ElNino.Commands.Pause,
    ElNino.Commands.Resume,
    ElNino.Commands.PlayNext,
    ElNino.Commands.Volume,
    ElNino.Commands.Leave
  ]

  defp register_all_commands_guild(guild_id) do
    case ApplicationCommand.bulk_overwrite_guild_commands(
           guild_id,
           @commands |> Enum.map(& &1.definition())
         ) do
      {:ok, _} ->
        IO.puts("Successfully registered all commands for guild #{guild_id}!")

      {:error, %Nostrum.Error.ApiError{response: response}} ->
        IO.puts("Failed to register commands for guild #{guild_id}! Error: #{response}")
    end
  end

  def register_all_commands_global() do
    case ApplicationCommand.bulk_overwrite_global_commands(
           @commands
           |> Enum.map(& &1.definition())
         ) do
      {:ok, _} ->
        IO.puts("Successfully registered all global commands!")

      {:error, %Nostrum.Error.ApiError{response: response}} ->
        IO.puts("Failed to register global commands! Error: #{response}")
    end
  end

  # Registering all slash commands on bot ready event
  # TODO: Redo to register only when needed
  def handle_event({:READY, _, _}) do
    Enum.each(@servers, fn guild_id -> register_all_commands_guild(guild_id) end)
  end

  def handle_event({
        :INTERACTION_CREATE,
        %Interaction{guild_id: guild_id, channel_id: channel_id} = interaction,
        _ws_state
      }) do
    if not is_nil(guild_id) and not is_nil(channel_id) do
      :ets.insert(:last_interaction, {guild_id, channel_id})
    end

    route_command(interaction)
  end

  def handle_event({:VOICE_STATE_UPDATE, _, _} = event),
    do: ElNino.Handlers.Voice.handle_event(event)

  def handle_event({:VOICE_SERVER_UPDATE, _, _} = event),
    do: ElNino.Handlers.Voice.handle_event(event)

  def handle_event({:VOICE_SPEAKING_UPDATE, payload, _ws_state}),
    do: Logger.debug("VOICE SPEAKING UPDATE #{inspect(payload)}")

  def handle_event(_), do: :ok

  defp route_command(%Interaction{data: %{name: name}} = interaction) do
    case Enum.find(@commands, fn command -> command.name() == name end) do
      nil ->
        Logger.error("No command found for interaction: #{name}")

      command ->
        command.handle(interaction)
    end
  end
end
