defmodule OfficeServerWeb.BoxComms.SocketHandlerTest do
  use OfficeServer.DataCase, async: false

  alias OfficeServer.Devices
  alias OfficeServerWeb.BoxComms.SocketHandler

  describe "authenticates" do
    test "checks the authentication" do
      assert SocketHandler.authenticate?(%{
               "username" => "test_user",
               "password" => "test_password",
               "fedecks-device-id" => "123"
             })

      refute SocketHandler.authenticate?(%{
               "username" => "test_user",
               "password" => "wrong_password",
               "fedecks-device-id" => "123"
             })

      refute SocketHandler.authenticate?(%{})
    end

    test "creates a new device entity if it does not already exist" do
      SocketHandler.subscribe_office_events()

      assert SocketHandler.authenticate?(%{
               "username" => "test_user",
               "password" => "test_password",
               "fedecks-device-id" => "device-123"
             })

      assert {:ok, %{device_id: "device-123", id: id}} = Devices.by_device_id("device-123")
      assert_receive {"office_events", :new_device, "device-123", %{id: ^id}}
    end

    test "succeeds if the device already exists" do
      SocketHandler.subscribe_office_events()
      Devices.create_device(%{device_id: "device-123"})

      assert SocketHandler.authenticate?(%{
               "username" => "test_user",
               "password" => "test_password",
               "fedecks-device-id" => "device-123"
             })

      refute_receive {"office_events", :new_device, _, _}
    end

    test "does not create device if authentication fails" do
      refute SocketHandler.authenticate?(%{
               "username" => "test_user",
               "password" => "wrong",
               "fedecks-device-id" => "device-123"
             })

      assert Devices.by_device_id("device-123") == {:error, :notfound}
    end
  end

  test "handle_in publishes messages" do
    SocketHandler.subscribe_office_events()

    SocketHandler.handle_in("device-123", %{"temperature" => "14.5"})

    assert_receive {"office_events", :device_msg, "device-123", %{"temperature" => "14.5"}}
  end

  describe "presence" do
    setup do
      OfficeServerWeb.Presence.subscribe_presence()

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

      assert topic == OfficeServerWeb.Presence.presence_topic()
      assert %{"a-device-id" => %{metas: [metas]}} = joins
      assert %{connected_at: %DateTime{}, pid: pid} = metas
      assert pid == self()
    end
  end
end
