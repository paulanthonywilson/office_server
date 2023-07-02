defmodule OfficeServer.AllDevicePubSubTest do
  use ExUnit.Case
  alias OfficeServer.AllDevicePubSub

  test "image subscriptions" do
    device_id = "device#{:rand.uniform()}#{:erlang.monotonic_time()}"
    AllDevicePubSub.subscribe_to_images(device_id)
    AllDevicePubSub.broadcast_image(device_id, "a pretend image")
    AllDevicePubSub.broadcast_image("other-device-id", "some image")

    assert_receive {:image, ^device_id, "a pretend image"}
    refute_receive {:image, "other-device-id", _}
  end
end
