defmodule ElNino.Embeds do
  @moduledoc """
  Provides functions to create Discord embeds for the ElNino bot.
  """

  alias Nostrum.Struct.Embed

  @doc """
  Returns color for info embeds.
  """
  def info_color, do: 6_036_244

  def error_color, do: 16_711_680

  @doc """
  Creates an embed for a song with the given title, URL, and thumbnail URL.
  """
  def song_added_to_queue(title, uri, author, artwork_url) do
    %Embed{}
    |> Embed.put_author("Added track to queue", nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_url(uri)
    |> Embed.put_field("Author", author)
    |> Embed.put_color(info_color())
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
    |> Embed.put_color(error_color())
  end

  @doc """
  Creates information embed with the given title and description.
  """
  def info(title, description) do
    %Embed{}
    |> Embed.put_author("Information", nil, nil)
    |> Embed.put_title(title)
    |> Embed.put_description(description)
    |> Embed.put_color(info_color())
  end
end
