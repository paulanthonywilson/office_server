defmodule OfficeServerWeb.OfficeLiveTest do
  use OfficeServerWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "mounting" do
    test "displays the box id", %{conn: conn} do
      assert {:ok, _live, html} = live(conn, "/devices/nerves-239e")
      assert html =~ "nerves-239e"
    end
  end

  describe "events" do
    test "currently listens to all office server events and lists them", %{conn: conn} do
      assert {:ok, live, _html} = live(conn, "/devices/nerves-239e")

      Phoenix.PubSub.broadcast(
        OfficeServer.PubSub,
        "office_events",
        {"office_events", "a device", "hello matey"}
      )

      assert live |> element("#events") |> render() =~ "hello matey"
    end
  end
end
