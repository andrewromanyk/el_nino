defmodule ElNino.Ecto.Schemas.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    field :guild_id, :string
    field :channel_id, :string

    timestamps()
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:guild_id, :channel_id])
    |> validate_required([:guild_id, :channel_id])
    |> unique_constraint(:guild_id)
  end
end
