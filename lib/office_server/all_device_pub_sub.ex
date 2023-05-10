defmodule OfficeServer.AllDevicePubSub do
  @moduledoc """
  Pub Sub for all devices on all sockets
  """

  @office_events_topic "office_events"

  @doc """
  Subscribe to office events notifications
  """
  def subscribe_office_events do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, @office_events_topic)
  end

  def broadcast_office_event(type, device_id, message) do
    Phoenix.PubSub.broadcast!(
      OfficeServer.PubSub,
      @office_events_topic,
      {@office_events_topic, type, device_id, message}
    )
  end
end
