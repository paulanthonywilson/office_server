defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  use OfficeServer.DeviceData

  def mount(%{"device_id" => device_id}, _session, socket) do
    socket =
      socket
      |> assign(:device_id, device_id)
      |> assign(:temperature, DeviceData.temperature(device_id))
      |> assign_occupation(DeviceData.occupation_status(device_id))

    if connected?(socket), do: DeviceData.subscribe(device_id)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 id="head"><%= @device_id %></h1>
    <.list>
      <:item title="Temperature"><.temperature temperature={@temperature} /></:item>
      <:item title="Last temperature reading">
        <.temperature_timestamp temperature={@temperature} />
      </:item>
      <:item title="Occupation">
        <.occupation occupation={@occupation} />
      </:item>
      <:item title={@occupation_timestamp_title}>
        <.occupation_timestamp occupation={@occupation} />
      </:item>
    </.list>
    """
  end

  def handle_info({:device_data, _device, :temperature, temperature}, socket) do
    {:noreply, assign(socket, :temperature, temperature)}
  end

  def handle_info({:device_data, _device, :occupation, occupation}, socket) do
    {:noreply, assign_occupation(socket, occupation)}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  defp assign_occupation(socket, occupation) do
    timestamp_title =
      case occupation do
        {:unoccupied, _} -> "Vacancy time"
        _ -> "Occupancy time"
      end

    socket
    |> assign(:occupation, occupation)
    |> assign(:occupation_timestamp_title, timestamp_title)
  end

  defp temperature(%{temperature: :unknown} = assigns) do
    ~H"""
    -
    """
  end

  defp temperature(%{temperature: {temperature, _}} = assigns) do
    temperature =
      temperature
      |> Decimal.round(1)
      |> Decimal.to_string()

    assigns = assign(assigns, temperature: temperature)

    ~H"""
    <%= @temperature %> ℃
    """
  end

  defp temperature_timestamp(%{temperature: :unknown} = assigns) do
    ~H"""
    -
    """
  end

  defp temperature_timestamp(%{temperature: {_, timestamp}} = assigns) do
    assigns = assign(assigns, :time, display_date_time(timestamp))

    ~H"""
    <%= @time %>
    """
  end

  defp occupation(%{occupation: :unknown} = assigns) do
    ~H"""
    -
    """
  end

  defp occupation(%{occupation: {state, _}} = assigns) do
    occupation =
      case state do
        :occupied -> "Occupied"
        :unoccupied -> "Vacant"
      end

    assigns = assign(assigns, :occupation, occupation)

    ~H"""
    <%= @occupation %>
    """
  end

  defp occupation_timestamp(%{occupation: :unknown} = assigns) do
    ~H"""
    -
    """
  end

  defp occupation_timestamp(%{occupation: {_, timestamp}} = assigns) do
    assigns = assign(assigns, :timestamp, display_date_time(timestamp))

    ~H"""
    <%= @timestamp %>
    """
  end

  defp display_date_time(timestamp) do
    timestamp
    |> DateTime.shift_zone!("Europe/London")
    |> Calendar.strftime("%H:%M:%S %d %b %Y %Z")
  end
end
