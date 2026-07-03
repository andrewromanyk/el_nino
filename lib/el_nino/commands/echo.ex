defmodule ElNino.Commands.Echo do
  @moduledoc """
  Command that returns the same message.
  """

  def name(), do: "echo"

  def definition() do
    %{
      name: name(),
      description: "Return with the same message.",
      options: [
        %{
          type: 3,
          name: "text",
          description: "text to echo",
          required: true
        }
      ]
    }
  end

  def handle(interaction) do
    response = %{
      type: 4,
      data: %{
        content: (interaction.data.options |> Enum.at(0)).value
      }
    }

    Nostrum.Api.Interaction.create_response(interaction, response)
  end
end
