defmodule ElNino.Commands.CreateManagerChannel do
  @moduledoc """
  Command that creates a manager channel.
  """

  alias ElNino.Embeds
  alias Nostrum.Struct.Interaction
  alias ElNino.Ecto.Schemas.Channel

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

  def handle(
        %Interaction{
          data: data,
          guild_id: guild_id
        } = interaction
      ) do

    case ElNino.Repo.get_by(Channel, guild_id: to_string(guild_id)) do
      nil ->
        options = data.options || []

        name = Enum.find_value(options, fn %{name: n, value: v} -> if n == "name", do: v end) || "manager-channel"
        category_id = Enum.find_value(options, fn %{name: n, value: v} -> if n == "category", do: v end) |> IO.inspect(label: "category_id")

        {:ok, channel} = Nostrum.Api.Channel.create(guild_id, %{
          name: name,
          type: 0,
          parent_id: category_id,
          permission_overwrites: [
            # all users can read and interact, but can't send messages
            %{
              deny: 0x0000000000000800,
              id: guild_id,
              type: 0
            },
            # bot can do everything
            %{
              allow: 0x0000000000000800,
              id: Nostrum.Cache.Me.get().id,
              type: 1
            }
          ]
        })

        ElNino.Response.response_with_embed(
          interaction,
          Embeds.one_liner_author("Manager channel created.")
        )

        Channel.changeset(%Channel{}, %{guild_id: to_string(guild_id), channel_id: to_string(channel.id)}) |> ElNino.Repo.insert()

      %Channel{channel_id: channel_id} ->
        ElNino.Response.response_with_embed(
          interaction,
          Embeds.two_liner_author_description("Manager channel already exists:", "<##{channel_id}>")
        )
    end
  end
end
