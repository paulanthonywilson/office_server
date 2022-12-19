defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  alias Ecto.UUID

  defmodule Event do
    defstruct [:id, :timestamp, :device, :message]
  end

  def mount(_params, _session, socket) do
    socket = assign(socket, events: [])

    Phoenix.PubSub.subscribe(OfficeServer.PubSub, "office_events")
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <p>Hello this is the Live View</p>
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
