defmodule OfficeServerWeb.OfficeLiveTest do
  use OfficeServerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mox

  defmodule StubDeviceData do
    @behaviour OfficeServer.DeviceData

    @impl OfficeServer.DeviceData
    def subscribe(_device_id), do: :ok
    @impl OfficeServer.DeviceData
    def temperature(_device_id), do: :unknown
    @impl OfficeServer.DeviceData
    def occupation_status(_device_id), do: :unknown
  end

  setup :verify_on_exit!

  setup do
    set_mox_global()
    stub_with(MockDeviceData, StubDeviceData)
    :ok
  end

  describe "mounting" do
    test "displays the box id", %{conn: conn} do
      assert {:ok, _live, html} = live(conn, "/devices/nerves-239e")
      assert html =~ "nerves-239e"
    end

    test "subscribes for device updates", %{conn: conn} do
      expect(MockDeviceData, :subscribe, fn device ->
        assert device == "nerves-239e"
      end)

      assert {:ok, _live, _html} = live(conn, "/devices/nerves-239e")
    end

    test "Displays no data when there is no data to display", %{conn: conn} do
      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")
      assert element_text(live, "dd[data-title='Temperature']") =~ "-"

      assert element_text(live, "dd[data-title='Last temperature reading']") =~ "-"

      assert element_text(live, "dd[data-title='Occupation']") =~ "-"
      assert element_text(live, "dd[data-title='Occupancy time']") =~ "-"
    end

    test "displays temperature when set", %{conn: conn} do
      stub(MockDeviceData, :temperature, fn "nerves-239e" ->
        {Decimal.new("21.2678"), ~U[2023-02-05 06:07:08Z]}
      end)

      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")
      assert element_text(live, "dd[data-title='Temperature']") =~ "21.3"

      assert element_text(live, "dd[data-title='Last temperature reading']") =~
               "06:07:08 05 Feb 2023"
    end

    test "displays occupation status when set", %{conn: conn} do
      stub(MockDeviceData, :occupation_status, fn "nerves-239e" ->
        {:occupied, ~U[2023-01-03 11:12:13Z]}
      end)

      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")

      assert element_text(live, "dd[data-title='Occupation']") =~ "Occupied"
      assert element_text(live, "dd[data-title='Occupancy time']") =~ "11:12:13 03 Jan 2023"
    end

    test "Occupation titles are 'Unoccupied' when unoccupied", %{conn: conn} do
      stub(MockDeviceData, :occupation_status, fn "nerves-239e" ->
        {:unoccupied, ~U[2023-01-03 11:12:13Z]}
      end)

      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")

      assert element_text(live, "dd[data-title='Occupation']") =~ "Vacant"
      assert element_text(live, "dd[data-title='Vacancy time']") =~ "11:12:13 03 Jan 2023"
    end

    test "times are in UK time", %{conn: conn} do
      stub(MockDeviceData, :occupation_status, fn "nerves-239e" ->
        {:occupied, ~U[2023-07-03 11:12:13Z]}
      end)

      stub(MockDeviceData, :temperature, fn "nerves-239e" ->
        {Decimal.new("21.2678"), ~U[2023-07-05 06:07:08Z]}
      end)

      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")
      assert element_text(live, "dd[data-title='Occupancy time']") =~ "12:12:13 03 Jul 2023 BST"

      assert element_text(live, "dd[data-title='Last temperature reading']") =~
               "07:07:08 05 Jul 2023 BST"
    end
  end

  describe "updating" do
    test "temperature", %{conn: conn} do
      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")

      send_device_event(live, :temperature, {Decimal.new("23.11"), ~U[2023-11-01 14:10:00Z]})

      assert element_text(live, "dd[data-title='Last temperature reading']") =~
               "14:10:00 01 Nov 2023 GMT"

      assert element_text(live, "dd[data-title='Temperature']") =~ "23.1"
    end

    test "occupancy", %{conn: conn} do
      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")

      send_device_event(live, :occupation, {:occupied, ~U[2023-03-01 10:00:00Z]})

      assert element_text(live, "dd[data-title='Occupation']") =~ "Occupied"
      assert element_text(live, "dd[data-title='Occupancy time']") =~ "10:00:00 01 Mar 2023 GMT"

      send_device_event(live, :occupation, {:unoccupied, ~U[2023-03-01 11:00:00Z]})

      assert element_text(live, "dd[data-title='Occupation']") =~ "Vacant"
      assert element_text(live, "dd[data-title='Vacancy time']") =~ "11:00:00 01 Mar 2023 GMT"
    end
  end

  defp send_device_event(%{pid: pid}, type, event) do
    send(pid, {:device_data, "nerves-239e", type, event})
    :sys.get_state(pid)
  end

  defp element_text(live, selector) do
    live
    |> element(selector)
    |> render()
    |> Floki.parse_document!()
    |> Floki.text()
  end
end
