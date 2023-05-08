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
      assert_receive :track_presence
    end

    test "tracks" do
      assert :ok = SocketHandler.handle_info("a-device-id", :track_presence)

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

    test "signals other sockets to shut down and reschedules tracking, if already detected" do
      test_pid = self()

      pids =
        for _ <- 1..3 do
          pid =
            spawn_link(fn ->
              receive do
                :please_stop ->
                  send(test_pid, {self(), :stop_request_received})
              after
                500 ->
                  :ok
              end
            end)

          OfficeServerWeb.Presence.track(pid, SocketHandler.presence_topic(), "device-123", %{
            connected_at: DateTime.utc_now(),
            pid: pid
          })

          pid
        end

      for _pid <- pids, do: assert_receive(%Phoenix.Socket.Broadcast{})

      assert :ok = SocketHandler.handle_info("device-123", :track_presence)

      for pid <- pids do
        assert_receive {^pid, :stop_request_received}
      end

      assert_receive :track_presence
    end
  end

  test "shutting down on request" do
    assert {:stop, _} = SocketHandler.handle_info("device-123", :please_stop)
  end
end
