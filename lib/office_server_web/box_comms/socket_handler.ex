defmodule OfficeServerWeb.BoxComms.SocketHandler do
  @moduledoc """
  Handles messages from a (the) security box.
  """

  @behaviour FedecksServer.FedecksHandler
  alias OfficeServer.{AllDevicePubSub, Authentication, Devices}

  alias FedecksServer.FedecksHandler

  use OfficeServer.DeviceData

  require Logger

  @doc """
  Subscribe to office events notifications
  """
  defdelegate subscribe_office_events, to: AllDevicePubSub

  @doc """
  Receive images from the specified device
  """
  defdelegate subscribe_to_images(device_id), to: AllDevicePubSub

  @impl FedecksHandler
  def authenticate?(%{
        "username" => username,
        "password" => password,
        "fedecks-device-id" => device_id
      }) do
    case Authentication.authenticate(username, password) do
      {:ok, _} ->
        case Devices.create_device(%{device_id: device_id}) do
          {:ok, device} ->
            AllDevicePubSub.broadcast_office_event(:new_device, device_id, device)

          _ ->
            nil
        end

        true

      _ ->
        false
    end
  end

  def authenticate?(_), do: false

  @impl FedecksHandler
  def otp_app, do: :office_server

  @impl FedecksHandler
  def handle_in(device_id, message) do
    AllDevicePubSub.broadcast_office_event(:device_msg, device_id, message)
  end

  @impl FedecksHandler
  def handle_raw_in(device_id, <<0xFF, 0xD8>> <> _ = message) do
    AllDevicePubSub.broadcast_image(device_id, message)
  end

  def handle_raw_in(_device_id, _message) do
    :ok
  end

  @impl FedecksHandler
  def connection_established(device_id, send_occupation_status_after \\ 500) do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, downstream_events_topic(device_id))
    send(self(), :track)

    # delay sending the occupation status a short while so it does not get mixed up with the upgrade response
    Process.send_after(self(), :send_occupation_status, send_occupation_status_after)
    :ok
  end

  @impl FedecksHandler
  def handle_info(device_id, :track) do
    case OfficeServerWeb.Presence.device_presences(device_id) do
      [] ->
        {:ok, _} = OfficeServerWeb.Presence.track_device(device_id, DateTime.utc_now())

      %{metas: metas} ->
        for %{pid: pid} <- metas, do: send(pid, :please_stop)
        Process.send_after(self(), :track, 50)
    end

    :ok
  end

  def handle_info(_device_id, {:send_downstream, message}) do
    {:push, message}
  end

  def handle_info(_device_id, :please_stop) do
    {:stop, "I am probably a zombie"}
  end

  def handle_info(device_id, :send_occupation_status) do
    {:push, {:occupation_status, DeviceData.occupation_status(device_id)}}
  end

  def send_to_device(device_id, message) do
    Phoenix.PubSub.broadcast(
      OfficeServer.PubSub,
      downstream_events_topic(device_id),
      {:send_downstream, message}
    )
  end

  defp downstream_events_topic(device_id) do
    "#{__MODULE__}.downstream.#{device_id}"
  end
end
