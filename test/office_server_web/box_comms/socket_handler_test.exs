defmodule OfficeServerWeb.BoxComms.SocketHandlerTest do
  use ExUnit.Case, async: false
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

  describe "presence" do
    setup do
      SocketHandler.subscribe_presence()

      on_exit(fn ->
        for pid <- OfficeServerWeb.Presence.fetchers_pids() do
          ref = Process.monitor(pid)
          assert_receive {:DOWN, ^ref, _, _, _}, 1000
        end
      end)

      :ok
    end

    test "sends message to self to track" do
      SocketHandler.connection_established("a-device-id")

      assert_receive %Phoenix.Socket.Broadcast{
        topic: topic,
        event: "presence_diff",
        payload: %{joins: joins}
      }

      assert topic == SocketHandler.presence_topic()
      assert %{"a-device-id" => %{metas: [metas]}} = joins
      assert %{connected_at: %DateTime{}, pid: pid} = metas
      assert pid == self()
    end
  end
end
