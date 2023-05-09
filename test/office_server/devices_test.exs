defmodule OfficeServer.DevicesTest do
  use OfficeServer.DataCase

  alias Ecto.Changeset
  alias OfficeServer.Devices

  describe "devices" do
    alias OfficeServer.Devices.Device

    import OfficeServer.DevicesFixtures

    @invalid_attrs %{device_id: nil}

    test "list_devices/0 returns all devices" do
      device = device_fixture()
      assert Devices.list_devices() == [device]
    end

    test "get_device!/1 returns the device with given id" do
      device = device_fixture()
      assert Devices.get_device!(device.id) == device
    end

    test "create_device/1 with valid data creates a device" do
      valid_attrs = %{device_id: "some device_id"}

      assert {:ok, %Device{} = device} = Devices.create_device(valid_attrs)
      assert device.device_id == "some device_id"
    end

    test "create_device/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Devices.create_device(@invalid_attrs)
    end

    test "create device which has already been created returns errot changeset" do
      assert {:ok, %Device{}} = Devices.create_device(%{device_id: "dev1"})
      assert {:ok, %Device{}} = Devices.create_device(%{device_id: "dev2"})

      assert {:error, %Changeset{} = cs} = Devices.create_device(%{device_id: "dev1"})

      assert %{device_id: ["has already been taken"]} = errors_on(cs)
    end

    test "delete_device/1 deletes the device" do
      device = device_fixture()
      assert {:ok, %Device{}} = Devices.delete_device(device)
      assert_raise Ecto.NoResultsError, fn -> Devices.get_device!(device.id) end
    end
  end
end
