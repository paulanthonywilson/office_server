defmodule OfficeServerWeb.OfficeListLive do
  use OfficeServerWeb, :live_view
  alias OfficeServer.Devices

  @presence_topic OfficeServerWeb.Presence.presence_topic()

  defmodule DeviceWithPresence do
    defstruct [:id, :present?]
  end

  def mount(_params, _sess, socket) do
    devices = Enum.map(Devices.list_devices(), &map_with_presence/1)
    socket = stream(socket, :devices, devices)
    OfficeServerWeb.Presence.subscribe_presence()
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <header>
      <h1>devices</h1>
    </header>
    <.table
      id="devices"
      rows={@streams.devices}
      row_click={fn {_id, device} -> JS.navigate(~p"/devices/#{device.id}") end}
    >
      <:col :let={{id, device}} label="Device"><%= device.id %></:col>
      <:col :let={{_id, device}} label=""><.presence present?={device.present?} /></:col>
    </.table>
    """
  end

  def handle_info(
        %Phoenix.Socket.Broadcast{
          topic: @presence_topic,
          event: "presence_diff",
          payload: %{joins: joins, leaves: leaves}
        },
        socket
      ) do
    socket =
      socket
      |> update_presence(joins, true)
      |> update_presence(leaves, false)

    {:noreply, socket}
  end

  defp update_presence(socket, presence_map, present?) do
    Enum.reduce(
      presence_map,
      socket,
      fn {device_id, _}, socket ->
        stream_insert(socket, :devices, %DeviceWithPresence{id: device_id, present?: present?})
      end
    )
  end

  defp map_with_presence(%{device_id: device_id}) do
    %DeviceWithPresence{
      id: device_id,
      present?: OfficeServerWeb.Presence.device_present?(device_id)
    }
  end

  defp presence(%{present?: true} = assigns) do
    ~H"""
    <span class="text-green-500">
      Connected
    </span>
    """
  end

  defp presence(assigns) do
    ~H"""

    """
  end
end
