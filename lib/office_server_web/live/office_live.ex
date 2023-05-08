defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  alias Ecto.UUID

  defmodule Event do
    defstruct [:id, :timestamp, :device, :message]
  end

  def mount(%{"device_id" => device_id}, _session, socket) do
    socket = assign(socket, events: [], device_id: device_id)

    Phoenix.PubSub.subscribe(OfficeServer.PubSub, "office_events")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 id="head"><%= @device_id %></h1>
    <.table id="events" rows={@events}>
      <:col :let={ev} label="Received"><%= ev.timestamp %></:col>
      <:col :let={ev} label="Device"><%= ev.device %></:col>
      <:col :let={ev} label="Message"><%= inspect(ev.message) %></:col>
    </.table>
    """
  end

  def handle_info({"office_events", device, message}, %{assigns: %{events: events}} = socket) do
    {:noreply,
     assign(socket, :events, [
       %Event{
         id: UUID.generate(),
         timestamp: DateTime.utc_now(),
         message: message,
         device: device
       }
       | events
     ])}
  end
end
