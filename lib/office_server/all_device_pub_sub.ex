defmodule OfficeServer.AllDevicePubSub do
  @moduledoc """
  Pub Sub for all devices on all sockets
  """

  @office_events_topic "office_events"
  @image_event_prefix "office_images."

  @pubsub OfficeServer.PubSub

  @doc """
  Subscribe to office events notifications
  """
  def subscribe_office_events do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, @office_events_topic)
  end

  def subscribe_to_images(device_id) do
    Phoenix.PubSub.subscribe(@pubsub, image_topic(device_id))
  end

  def broadcast_image(device_id, image) do
    Phoenix.PubSub.broadcast(@pubsub, image_topic(device_id), {:image, device_id, image})
  end

  def broadcast_office_event(type, device_id, message) do
    Phoenix.PubSub.broadcast!(
      @pubsub,
      @office_events_topic,
      {@office_events_topic, type, device_id, message}
    )
  end

  defp image_topic(device_id), do: @image_event_prefix <> device_id
end
