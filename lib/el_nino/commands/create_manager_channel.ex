defmodule ElNino.Commands.CreateManagerChannel do
  @moduledoc """
  Command that creates a manager channel.
  """

  alias ElNino.Embeds
  alias Nostrum.Struct.Interaction

  def name(), do: "create_manager_channel"

  def definition() do
    %{
      name: name(),
      description: "Creates a manager channel for the current guild.",
      options: [
        %{
          type: 3,
          name: "name",
          description: "The name of the manager channel to create",
          required: false
        },
        %{
          type: 7,
          name: "category",
          description: "The category for the manager channel",
          required: false
        }
      ]
    }
  end

def handle(%Interaction{data: data, guild_id: guild_id} = interaction) do
    case ElNino.ChannelStore.get(guild_id) do
      {:error, reason} ->
        ElNino.Response.response_with_embed(
          interaction,
          Embeds.one_liner_author("Error retrieving manager channel. Reason: #{inspect(reason)}")
        )

      :not_found ->
        create_and_store_channel(interaction, guild_id, data)

      {:ok, channel_id} ->
        if ElNino.Discord.Common.channel_exists?(guild_id, channel_id) do
          ElNino.Response.response_with_embed(
            interaction,
            Embeds.two_liner_author_description("Manager channel already exists:", "<##{channel_id}>")
          )
        else
          create_and_store_channel(interaction, guild_id, data)
        end
    end
  end

  defp create_and_store_channel(interaction, guild_id, data) do
    options = data.options || []

    name = Enum.find_value(options, fn %{name: n, value: v} -> if n == "name", do: v end) || "manager-channel"
    category_id = Enum.find_value(options, fn %{name: n, value: v} -> if n == "category", do: v end)

    {:ok, channel} = Nostrum.Api.Channel.create(guild_id, %{
      name: name,
      type: 0,
      parent_id: category_id,
      permission_overwrites: [
        %{
          deny: 0x0000000000000800,
          id: guild_id,
          type: 0
        },
        %{
          allow: 0x0000000000000800,
          id: Nostrum.Cache.Me.get().id,
          type: 1
        }
      ]
    })

    ElNino.Response.response_with_embed(
      interaction,
      Embeds.two_liner_author_description("Manager channel created:", "<##{channel.id}>")
    )

    Nostrum.Api.Message.create(channel.id, "Placeholder message for the manager channel. This channel is used to manage the bot's music playback.")

    ElNino.ChannelStore.put(guild_id, channel.id)
  end
end
