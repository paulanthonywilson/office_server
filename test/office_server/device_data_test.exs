defmodule OfficeServer.DeviceDataTest do
  use ExUnit.Case, async: true
  alias OfficeServer.DeviceData

  import Mox

  setup :verify_on_exit!

  @now ~U[2023-05-10 15:34:42.230525Z]
  setup do
    unique_name = :"#{__MODULE__}.#{inspect(self())}"

    stub(MockClock, :utc_now, fn -> @now end)

    {:ok, pid} = start_supervised({DeviceData, name: unique_name})
    allow(MockClock, self(), pid)
    {:ok, pid: pid, name: unique_name}
  end

  describe "temperature" do
    test "unknown when no temperature has been received", %{name: name} do
      assert :unknown == DeviceData.temperature(name, "device-123")
    end

    test "returns temperature once received", %{name: name, pid: pid} do
      device_message(pid, "device-123", %{"temperature" => Decimal.new("11.5")})

      assert {temp, @now} = DeviceData.temperature(name, "device-123")
      assert Decimal.eq?("11.5", temp)
    end

    test "temperature scoped to the device", %{name: name, pid: pid} do
      pid
      |> device_message("device-123", %{"temperature" => Decimal.new("11.5")})
      |> device_message("device-456", %{"temperature" => Decimal.new("18.5")})

      assert {temp, @now} = DeviceData.temperature(name, "device-123")
      assert Decimal.eq?("11.5", temp)

      assert {temp, @now} = DeviceData.temperature(name, "device-456")
      assert Decimal.eq?("18.5", temp)
    end

    test "updates to new temperature", %{pid: pid, name: name} do
      pid
      |> device_message("device-123", %{"temperature" => Decimal.new("11.5")})
      |> device_message("device-123", %{"temperature" => Decimal.new("18.5")})

      assert {temp, @now} = DeviceData.temperature(name, "device-123")
      assert Decimal.eq?("18.5", temp)
    end

    test "new temperature is broadcast to subscribers", %{pid: pid} do
      device = "#{__MODULE__}-device"
      DeviceData.subscribe(device)

      pid
      |> device_message(device, %{"temperature" => Decimal.new("18.5")})
      |> device_message("DeviceDataTest.other-device", %{"temperature" => Decimal.new("12.5")})

      assert_receive {:device_data, ^device, :temperature, temp}
      refute_receive {:device_data, "DeviceDataTest.other-device", _, _}
      assert Decimal.eq?("18.5", temp)
    end
  end

  describe "occupied messages" do
    test "when unknown", %{name: name} do
      assert :unknown == DeviceData.occupation_status(name, "device-12")
    end

    test "when occupied", %{name: name, pid: pid} do
      device_message(pid, "device-11", %{"occupied" => ~U[2022-11-10 10:10:10Z]})

      assert {:occupied, ~U[2022-11-10 10:10:10Z]} ==
               DeviceData.occupation_status(name, "device-11")
    end

    test "when unoccupied", %{name: name, pid: pid} do
      device_message(pid, "device-11", %{"unoccupied" => ~U[2022-11-10 10:10:10Z]})

      assert {:unoccupied, ~U[2022-11-10 10:10:10Z]} ==
               DeviceData.occupation_status(name, "device-11")
    end

    test "last occupation counts", %{name: name, pid: pid} do
      pid
      |> device_message("device-13", %{"unoccupied" => ~U[2022-11-10 10:10:10Z]})
      |> device_message("device-13", %{"occupied" => ~U[2022-11-10 11:10:10Z]})
      |> device_message("device-13", %{"unoccupied" => ~U[2022-11-12 10:10:10Z]})

      assert {:unoccupied, ~U[2022-11-12 10:10:10Z]} ==
               DeviceData.occupation_status(name, "device-13")
    end

    test "occupation status is broadcast", %{pid: pid} do
      device = "#{__MODULE__}-device"
      DeviceData.subscribe(device)

      pid
      |> device_message(device, %{"occupied" => @now})

      assert_receive {:device_data, ^device, :occupation, {:occupied, @now}}

      pid
      |> device_message(device, %{"unoccupied" => @now})

      assert_receive {:device_data, ^device, :occupation, {:unoccupied, @now}}
    end
  end

  test "other messages are ignored", %{pid: pid} do
    device_message(pid, "nerves123", %{"movement_stop" => @now})
    assert Process.alive?(pid)
  end

  defp device_message(pid, device, message) do
    send(pid, {"office_events", :device_message, device, message})

    :sys.get_state(pid)
    pid
  end
end
