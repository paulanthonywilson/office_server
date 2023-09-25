defmodule OfficeServer.Temperatures.Temperature do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "temperatures" do
    field :device_id, :string
    field :temperature, :decimal
    field :recorded_time, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(temperature, attrs) do
    temperature
    |> cast(attrs, [:device_id, :temperature, :recorded_time])
    |> validate_required([:device_id, :temperature, :recorded_time])
  end
end
