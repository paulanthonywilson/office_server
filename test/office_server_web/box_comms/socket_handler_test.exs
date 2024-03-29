defmodule OfficeServerWeb.BoxComms.SocketHandlerTest do
  use OfficeServer.DataCase, async: false

  alias OfficeServer.Devices
  alias OfficeServerWeb.BoxComms.SocketHandler

  setup do
    Mox.set_mox_global()
    Mox.stub(MockClock, :utc_now, fn -> DateTime.utc_now() end)
    :ok
  end

  import Mox

  setup :verify_on_exit!

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

  describe "handle_raw_in " do
    setup do
      SocketHandler.subscribe_to_images("device-123")
    end

    test "publishes jpegs to the images topic" do
      SocketHandler.handle_raw_in("device-123", <<0xFF, 0xD8>> <> "looks like a jpeg")

      assert_receive {:image, "device-123", <<0xFF, 0xD8>> <> "looks like a jpeg"}
    end

    test "does not publish raw messages that do not look like jpegs to the images topic" do
      SocketHandler.handle_raw_in("device-123", "does not look like a jpeg")
      refute_receive {:image, "device-123", _}
    end
  end

  describe "sending occupation status on connection" do
    test "sends message to self to send occupation status" do
      SocketHandler.connection_established("a-device-id", 1)
      assert_receive :send_occupation_status
    end

    test "sends unknown no occupation status if it is not known" do
      expect(MockDeviceData, :occupation_status, fn "device-id" ->
        :unknown
      end)

      assert {:push, {:occupation_status, :unknown}} ==
               SocketHandler.handle_info("device-id", :send_occupation_status)
    end

    test ~c"sends occupation status if it is known" do
      expect(MockDeviceData, :occupation_status, fn "device-id" ->
        {:occupied, ~U[2023-07-01 12:13:14Z]}
      end)

      assert {:push, {:occupation_status, {:occupied, ~U[2023-07-01 12:13:14Z]}}} ==
               SocketHandler.handle_info("device-id", :send_occupation_status)
    end
  end

  describe "presence" do
    setup do
      OfficeServerWeb.Presence.subscribe_presence()

      on_exit(&TearDownPresence.tear_down/0)

      :ok
    end

    test "sends message to self to track" do
      SocketHandler.connection_established("a-device-id")
      assert_receive :track
    end

    test "tracks on receiving the :track message" do
      SocketHandler.handle_info("a-device-id", :track)

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

    test "if the device is already connected to a socket reschedules the tracking, after asking the connected sockets to stop" do
      refs =
        for _ <- 1..2 do
          fn ->
            OfficeServerWeb.Presence.track_device("double-device", ~U[2022-11-01 01:02:03Z])

            receive do
              :please_stop ->
                :ok
            end
          end
          |> spawn_link()
          |> Process.monitor()
        end

      # Wait for the presence to be recorded
      assert_receive %Phoenix.Socket.Broadcast{payload: %{joins: %{"double-device" => _}}}
      assert_receive %Phoenix.Socket.Broadcast{payload: %{joins: %{"double-device" => _}}}

      SocketHandler.handle_info("double-device", :track)

      for ref <- refs, do: assert_receive({:DOWN, ^ref, _, _, _})

      assert_receive :track
    end

    test "will stop when asked" do
      assert {:stop, _} = SocketHandler.handle_info("a-device", :please_stop)
    end
  end

  describe "sending downstream messages for device" do
    test ": subscribes on connect" do
      SocketHandler.connection_established("my-device")
      SocketHandler.send_to_device("my-device", {"discount", "tents"})
      assert_receive {:send_downstream, {"discount", "tents"}}
    end

    test ": only subscribes for device" do
      SocketHandler.connection_established("my-device")
      SocketHandler.send_to_device("another-device", {"discount", "tents"})
      refute_receive {:send_downstream, _}
    end

    test "will send the message downstream" do
      assert {:push, "some message"} ==
               SocketHandler.handle_info("device123", {:send_downstream, "some message"})
    end
  end
end
