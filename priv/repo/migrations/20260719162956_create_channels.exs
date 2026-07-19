defmodule ElNino.Repo.Migrations.CreateChannels do
  use Ecto.Migration

  def change do
    create table(:channels) do
      add :guild_id,    :string, null: false, size: 20
      add :channel_id,  :string, null: false

      timestamps()
    end

    create unique_index(:channels, [:guild_id])
  end
end
