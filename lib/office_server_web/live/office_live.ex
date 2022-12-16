defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  alias Ecto.UUID

  defmodule Event do
    defstruct [:id, :timestamp, :message]
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
      <:col :let={ev} label="Reveived"><%= ev.timestamp %></:col>
      <:col :let={ev} label="Message"><%= ev.message %></:col>
    </.table>
    """
  end

  def handle_info(message, %{assigns: %{events: events}} = socket) do
    {:noreply,
     assign(socket, :events, [
       %Event{id: UUID.generate(), timestamp: DateTime.utc_now(), message: message} | events
     ])}
  end
end
