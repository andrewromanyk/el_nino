defmodule ElNino.Commands.PlayNext do
  @moduledoc """
  Command that plays the next song in the queue.
  """

  alias ElNino.{Discord, Colors}
  alias Nostrum.Struct.Interaction

  def name(), do: "play_next"

  def definition() do
    %{
      name: name(),
      description: "Play the next song in the queue."
    }
  end

  def handle(%Interaction{guild_id: guild_id} = interaction) do
    case Discord.Common.get_voice_channel_of_bot(guild_id) do
      nil ->
        ElNino.Response.response_with_embed(
          interaction,
          ElNino.Embeds.one_liner_author(
            "Bot not in voice channel.",
            Colors.warn_color()
          )
        )

      _channel_id ->
        case ElNino.SongManager.play_next(guild_id) do
          {:ok, _message} ->
            ElNino.Response.response_with_embed(
              interaction,
              ElNino.Embeds.one_liner_author("Playing next track")
            )

          {:error, message} ->
            ElNino.Response.response_with_embed(
              interaction,
              ElNino.Embeds.one_liner_author(
                "Cannot play the next track: #{message}",
                Colors.error_color()
              )
            )
        end
    end
  end
end
