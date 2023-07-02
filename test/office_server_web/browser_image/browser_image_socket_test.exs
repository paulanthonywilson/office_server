defmodule OfficeServerWeb.BrowserImage.BrowserImageSocketTest do
  use OfficeServerWeb.ConnCase, async: true

  alias OfficeServer.AllDevicePubSub
  alias OfficeServerWeb.BrowserImage.{BrowserImageSocket, DeviceToken}

  describe "initiation" do
    test "connects if the device is valid" do
      req =
        "device-456"
        |> DeviceToken.to_token()
        |> req()

      assert {:ok, %{device_id: "device-456", refresh: DeviceToken.refresh_milliseconds()}} ==
               BrowserImageSocket.connect(req)
    end

    test "invalid token" do
      assert :error == BrowserImageSocket.connect(req("blah"))
    end

    test "expired token" do
      assert {:ok, :expired_token} == BrowserImageSocket.connect(req(expired_token()))
      assert {:ok, :expired_token} == BrowserImageSocket.init(:expired_token)
      assert_received :expired_token

      assert {:push, {:text, "expired_token"}, :expired_token} ==
               BrowserImageSocket.handle_info(:expired_token, :expired_token)

      assert_received :close_socket

      assert {:stop, :closed, :expired_token} ==
               BrowserImageSocket.handle_info(:close_socket, :expired_token)
    end
  end

  describe "refreshing a token" do
    test "refresh initiated on init" do
      state = %{device_id: "123", refresh: 1}
      assert {:ok, ^state} = BrowserImageSocket.init(state)
      assert_receive :refresh_token
    end

    test "refresh is timed on init" do
      {:ok, _} = BrowserImageSocket.init(%{device_id: "123", refresh: 10_000})

      refute_receive :refresh_token
    end

    test "token refresh" do
      state = %{device_id: "123", refresh: 1}

      assert {:push, {:text, "token:" <> token}, ^state} =
               BrowserImageSocket.handle_info(:refresh_token, state)

      assert {:ok, "123"} = DeviceToken.from_token(token)
    end

    test "token refresh scheduled after a token refresh" do
      {:push, _, _} =
        BrowserImageSocket.handle_info(:refresh_token, %{device_id: "123", refresh: 1})

      assert_receive :refresh_token

      {:push, _, _} =
        BrowserImageSocket.handle_info(:refresh_token, %{device_id: "123", refresh: 10_000})

      refute_receive :refresh_token
    end
  end

  test "subscribes to images on ini" do
    device_id = "device#{:erlang.monotonic_time()}:#{:rand.uniform()}"
    {:ok, _} = BrowserImageSocket.init(%{device_id: device_id, refresh: 10_000})

    AllDevicePubSub.broadcast_image(device_id, "pretend i am an image")
    assert_receive {:image, ^device_id, "pretend i am an image"}
  end

  test "sending an image" do
    state = %{device_id: "123", refresh: 10_000}

    assert {:push, {:binary, "Pretend I'm an image"}, ^state} =
             BrowserImageSocket.handle_info({:image, "123", "Pretend I'm an image"}, state)
  end

  defp req(token) do
    %{params: %{"token" => token}}
  end

  defp expired_token do
    secrets = Application.fetch_env!(:office_server, DeviceToken)
    Plug.Crypto.encrypt(secrets[:secret], secrets[:salt], 1, signed_at: 0)
  end
end
