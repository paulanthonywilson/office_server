defmodule OfficeServerWeb.OfficeListLiveTest do
  use OfficeServerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias OfficeServer.Devices

  setup do
    devices =
      for i <- 1..3 do
        {:ok, device} = Devices.create_device(%{device_id: "device-#{i}"})
        device
      end

    {:ok, devices: devices}
  end

  test "shows the list of known devices", %{conn: conn} do
    assert {:ok, live, _html} = live(conn, "/")
    device_table = live |> element("#devices") |> render()
    assert device_table =~ "device-1"
    assert device_table =~ "device-2"
  end

  test "shows presence on load", %{conn: conn} do
    OfficeServerWeb.Presence.track_device("device-1", ~U[2023-04-01 12:11:00Z])

    assert {:ok, live, _html} = live(conn, "/")

    device_1_row = live |> element("#devices #devices-device-1") |> render()
    assert device_1_row =~ "Connected"
    device_2_row = live |> element("#devices #devices-device-2") |> render()
    refute device_2_row =~ "Connected"
  end

  test "updates connected when leaves", %{conn: conn} do
    OfficeServerWeb.Presence.track_device("device-1", ~U[2023-04-01 12:11:00Z])

    assert {:ok, %{pid: pid} = live, _html} = live(conn, "/")

    send(pid, %Phoenix.Socket.Broadcast{
      topic: OfficeServerWeb.Presence.presence_topic(),
      event: "presence_diff",
      payload: %{joins: %{}, leaves: %{"device-1" => []}}
    })

    :sys.get_state(pid)

    device_1_row = live |> element("#devices #devices-device-1") |> render()
    refute device_1_row =~ "Connected"
  end

  test "updates connected when joins", %{conn: conn} do
    assert {:ok, %{pid: pid} = live, _html} = live(conn, "/")

    send(pid, %Phoenix.Socket.Broadcast{
      topic: OfficeServerWeb.Presence.presence_topic(),
      event: "presence_diff",
      payload: %{joins: %{"device-2" => []}, leaves: %{}}
    })

    :sys.get_state(pid)
    device_2_row = live |> element("#devices #devices-device-2") |> render()
    assert device_2_row =~ "Connected"
  end
end
