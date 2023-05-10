defmodule OfficeServerWeb.BoxComms.SocketHandler do
  @moduledoc """
  Handles messages from a (the) security box.
  """

  @behaviour FedecksServer.FedecksHandler
  alias OfficeServer.{Authentication, Devices}

  alias FedecksServer.FedecksHandler

  import OfficeServer.AllDevicePubSub, only: [broadcast_office_event: 3]

  require Logger

  @doc """
  Subscribe to office events notifications
  """
  defdelegate subscribe_office_events, to: OfficeServer.AllDevicePubSub

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
            broadcast_office_event(:new_device, device_id, device)

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
    broadcast_office_event(:device_msg, device_id, message)
  end

  @impl FedecksHandler
  def connection_established(_device_id) do
    send(self(), :track)
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

  def handle_info(_device_id, :please_stop) do
    {:stop, "I am probably a zombie"}
  end
end
