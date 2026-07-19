defmodule ElNino.Embeds do
  @moduledoc """
  Provides functions to create Discord embeds for the ElNino bot.
  """

  alias Nostrum.Struct.Embed
  alias ElNino.Colors

  @doc """
  Creates an embed for a song with the given title, URL, and thumbnail URL.
  """
  def song_added_to_queue(title, uri, author, artwork_url, length) do
    %Embed{}
    |> Embed.put_author("Added track to queue", nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_url(uri)
    |> Embed.put_field("Author", author, true)
    |> Embed.put_field("Length", ElNino.Common.ms_to_str(length), true)
    |> Embed.put_color(Colors.info_color())
    |> Embed.put_thumbnail(artwork_url)
  end

  def playlist_added_to_queue(name, artwork_url, uri, track_count, playlist_length) do
    %Embed{}
    |> Embed.put_author("Added playlist to queue", nil, nil)
    |> Embed.put_title(name)
    |> Embed.put_url(uri)
    |> Embed.put_field("Tracks", track_count, true)
    |> Embed.put_field("Length", ElNino.Common.ms_to_str(playlist_length), true)
    |> Embed.put_color(Colors.info_color())
    |> Embed.put_thumbnail(artwork_url)
  end

  @doc """
  Creates an embed for an error display with the given title and error message.
  """
  def error(title, message) do
    %Embed{}
    |> Embed.put_author("Error", nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_description(message)
    |> Embed.put_color(Colors.error_color())
  end

  @doc """
  Creates information embed with the given title and description.
  """
  def info(title, description) do
    %Embed{}
    |> Embed.put_author("Information", nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_description(description)
    |> Embed.put_color(Colors.info_color())
  end

  def one_liner_author(text, color \\ Colors.info_color()) do
    %Embed{}
    |> Embed.put_author(text, nil, nil)
    |> Embed.put_color(color)
  end

  def one_liner_description(text, color \\ Colors.info_color()) do
    %Embed{}
    |> Embed.put_description(text)
    |> Embed.put_color(color)
  end

  def two_liner_author_description(author, description, color \\ Colors.info_color()) do
    %Embed{}
    |> Embed.put_author(author, nil, nil)
    |> Embed.put_description(description)
    |> Embed.put_color(color)
  end

  def current_song_embed(title, uri, author, artwork_url, length, text \\ "Currently playing") do
    %Embed{}
    |> Embed.put_author(text, nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_url(uri)
    |> Embed.put_field("Author", author, true)
    |> Embed.put_field("", "", true)
    |> Embed.put_field("Length", ElNino.Common.ms_to_str(length), true)
    |> Embed.put_color(Colors.info_color())
    |> Embed.put_thumbnail(artwork_url)
  end

  def queue_embed(queue, color \\ Colors.warn_color()) do
    case queue do
      [] ->
        %Embed{}
        |> Embed.put_title("Current Queue")
        |> Embed.put_description("The queue is currently empty.")
        |> Embed.put_color(color)

      _ ->
      old_len = length(queue)
      queue = Enum.take(queue, 6)
      new_len = length(queue)
      overflow = old_len - new_len
      [first | _] = tracks = ElNino.Lavalink.Client.decode_tracks(queue)

      base_embed =
        %Embed{}
        |> Embed.put_title("Current Queue")
        |> Embed.put_color(color)
        |> Embed.put_thumbnail(first["info"]["artworkUrl"])


      embed = Enum.reduce(tracks, base_embed, fn track, current_embed ->
        info = track["info"]

        current_embed
        |> Embed.put_field(
          info["title"],
          "[#{info["author"]}](#{info["uri"]})",
          true
        )
        |> Embed.put_field(
          "",
          "",
          true
        )
        |> Embed.put_field(
          "Duration",
          ElNino.Common.ms_to_str(info["length"]),
          true
        )
        |> Embed.put_field(
          "",
          "",
          false
        )
      end)

      if overflow > 0 do
        embed
        |> Embed.put_field(
          "And #{overflow} more tracks...",
          "",
          false
        )
      else
        embed
      end
    end
  end
end
