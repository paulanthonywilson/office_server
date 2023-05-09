defmodule OfficeServer.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :device_id, :string, null: false

      timestamps()
    end

    create index(:devices, :device_id, unique: true)
  end
end
