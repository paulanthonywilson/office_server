defmodule OfficeServerWeb.BrowserImageTest do
  use ExUnit.Case
  alias OfficeServerWeb.BrowserImage

  describe "base_ws_url" do
    test "wss or ws chosen by the http scheme" do
      assert "ws://localhost/images/" = BrowserImage.base_ws_url("http://localhost")
      assert "wss://localhost/images/" <> _ = BrowserImage.base_ws_url("https://localhost")

      assert "wss://localhost:4043/images/" <> _ =
               BrowserImage.base_ws_url("https://localhost:4043")
    end

    test "uses the endpoint static url if nothing added" do
      assert "ws://localhost:4002/images/" == BrowserImage.base_ws_url()
    end
  end
end
