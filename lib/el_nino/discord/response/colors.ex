defmodule ElNino.Colors do
  @moduledoc """
  Provides color constants for Discord embeds used in the ElNino bot.
  """

  @info_color 5_971_222
  @warn_color 3_091_757
  @error_color 3_547_942

  @doc """
  Returns the color for info embeds.
  """
  def info_color, do: @info_color

  @doc """
  Returns the color for error embeds.
  """
  def error_color, do: @error_color

  @doc """
  Returns the color for warning embeds.
  """
  def warn_color, do: @warn_color
end
