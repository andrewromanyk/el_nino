defmodule ElNino.DefCommands do
  @moduledoc """
  Module that returns definitions of commands ready for registration.

  Each function is a separate command.
  """

  def echo() do
    %{
      name: "echo",
      description: "return with the same message",
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

end
