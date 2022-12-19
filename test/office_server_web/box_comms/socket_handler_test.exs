defmodule OfficeServerWeb.BoxComms.SocketHandlerTest do
  use ExUnit.Case
  alias OfficeServerWeb.BoxComms.SocketHandler

  test "authenticates" do
    assert SocketHandler.authenticate?(%{"username" => "test_user", "password" => "test_password"})

    refute SocketHandler.authenticate?(%{
             "username" => "test_user",
             "password" => "wrong_password"
           })

    refute SocketHandler.authenticate?(%{})
  end

  test "handle_in publishes messages" do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, "office_events")

    SocketHandler.handle_in("device-123", %{"temperature" => "14.5"})

    assert_receive {"office_events", "device-123", %{"temperature" => "14.5"}}
  end
end
