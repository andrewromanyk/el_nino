defmodule ElNino.Consumer do
  @behaviour Nostrum.Consumer

  def handle_event({:READY, _, _}) do
    case Nostrum.Api.ApplicationCommand.create_guild_command(966052378023444560, ElNino.DefCommands.echo()) do
      {:ok, _} -> IO.puts("Successfully registered echo command!")
      _ -> IO.puts("Failed to register echo command!")
    end
  end

  def handle_event(_event = {:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "!hello" ->
        {:ok, _message} = Nostrum.Api.Message.create(msg.channel_id, "Hello, world!")

      _ ->
        :ignore
    end
  end

  def handle_event(_event = {:INTERACTION_CREATE, interaction, _ws_state}) do
    response = %{
      type: 4,  # ChannelMessageWithSource
      data: %{
        content: (interaction.data.options |> Enum.at(0)).value
      }
    }
    Nostrum.Api.Interaction.create_response(interaction, response)
  end

  def handle_event(_), do: :ok
end
