defmodule ElNino.Response do
  @moduledoc """
  Provides functions to create Discord responses for the ElNino bot.
  """

  alias Nostrum.Api
  alias Nostrum.Struct.Interaction

  @doc """
  Creates a response for an interaction with the given type and data. High-level wrapper around `Nostrum.Api.Interaction.create_response/3`.
  It is adviced to use more fine-grained functions in this module.
  """
  def response(%Interaction{id: id, token: token}, type, data) do
    Api.Interaction.create_response(id, token, %{
      type: type,
      data: data
    })
  end

  @doc """
  Creates a response for an interaction with the given embed.
  """
  def response_with_embed(%Interaction{} = interaction, embed) do
    response(interaction, 4, %{embeds: [embed]})
  end
end
