defmodule ElNino.DefCommands do
  @moduledoc """
  Module that returns definitions of commands ready for registration.

  Each function is a separate command.
  """

  def echo() do
    %{
      name: "echo",
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

  def join() do
    %{
      name: "join",
      description: "Make bot join the Voice Chat the caller is currently in."
    }
  end

  def play_music() do
    %{
      name: "play_music",
      description: "Play music in the current voice channel.",
      options: [
        %{
          type: 3,
          name: "url",
          description: "url to the video to play",
          required: true
        }
      ]
    }
  end

end
