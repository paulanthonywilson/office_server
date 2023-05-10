defmodule OfficeServer.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @opaque t :: %__MODULE__{}

  schema "devices" do
    field :device_id, :string

    timestamps()
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id])
    |> validate_required([:device_id])
    |> unique_constraint(:device_id)
  end
end
