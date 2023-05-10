defmodule OfficeServerWeb.OfficeLiveTest do
  use OfficeServerWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "mounting" do
    test "displays the box id", %{conn: conn} do
      assert {:ok, _live, html} = live(conn, "/devices/nerves-239e")
      assert html =~ "nerves-239e"
    end

    test "Displays the current temperature" do
    end
  end
end
