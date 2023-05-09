defmodule OfficeServer.DevicesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `OfficeServer.Devices` context.
  """

  @doc """
  Generate a device.
  """
  def device_fixture(attrs \\ %{}) do
    {:ok, device} =
      attrs
      |> Enum.into(%{
        device_id: "some device_id"
      })
      |> OfficeServer.Devices.create_device()

    device
  end
end
