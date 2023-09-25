defmodule OfficeServer.Repo.Migrations.CreateTemperatures do
  use Ecto.Migration

  def change do
    create table(:temperatures) do
      add :device_id, :string, null: false
      add :temperature, :decimal, null: false
      add :recorded_time, :utc_datetime, null: false

      timestamps()
    end

    create index(:temperatures, [:device_id, :recorded_time])
  end
end
