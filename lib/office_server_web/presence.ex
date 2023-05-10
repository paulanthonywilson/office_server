defmodule OfficeServerWeb.Presence do
  use Phoenix.Presence, otp_app: :office_server, pubsub_server: OfficeServer.PubSub

  @presence_topic to_string(__MODULE__)
  def presence_topic, do: @presence_topic

  @doc """
  Track the presence of the device with the current process
  """
  @spec track_device(device_id :: String.t(), connected_at :: DateTime.t()) ::
          {:error, any()} | {:ok, String.t()}
  def track_device(device_id, connected_at) do
    OfficeServerWeb.Presence.track(self(), @presence_topic, device_id, %{
      connected_at: connected_at,
      pid: self()
    })
  end

  @doc """
  Subscribe to presence notifications
  """
  def subscribe_presence do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, @presence_topic)
  end

  @doc """
  Is the device present
  """
  @spec device_present?(device_id :: String.t()) :: boolean()
  def device_present?(device_id) do
    [] != get_by_key(@presence_topic, device_id)
  end
end
