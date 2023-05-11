defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  use OfficeServer.DeviceData
  require Logger

  def mount(%{"device_id" => device_id}, _session, socket) do
    socket =
      socket
      |> assign(:device_id, device_id)
      |> assign(:temperature, DeviceData.temperature(device_id))
      |> assign_occupation(DeviceData.occupation_status(device_id))
      |> assign_connected(device_id)

    if connected?(socket) do
      DeviceData.subscribe(device_id)
      OfficeServerWeb.Presence.subscribe_presence()
    end

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 id="head"><%= @device_id %></h1>
    <.list>
      <:item title="Connected"><.connected connected_at={@connected_at} /></:item>
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

  def handle_info(
        %Phoenix.Socket.Broadcast{
          event: "presence_diff",
          payload: %{joins: joins, leaves: leaves}
        },
        %{assigns: %{device_id: device_id}} = socket
      ) do
    socket =
      socket
      |> assign_not_connected_if_in_leaves(leaves, device_id)
      |> assign_connected_if_in_joins(joins, device_id)

    {:noreply, socket}
  end

  def handle_info(msg, socket) do
    Logger.debug(fn -> "unexpected msg in OfficeLive: #{inspect(msg)}" end)
    {:noreply, socket}
  end

  defp assign_connected_if_in_joins(socket, joins, device_id) do
    case Map.get(joins, device_id) do
      %{metas: [%{connected_at: connected_at}]} ->
        assign(socket, :connected_at, connected_at)

      nil ->
        socket
    end
  end

  defp assign_not_connected_if_in_leaves(socket, leaves, device_id) do
    case Map.get(leaves, device_id) do
      nil ->
        socket

      _ ->
        assign(socket, :connected_at, nil)
    end
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

  defp assign_connected(socket, device_id) do
    connected_at =
      case OfficeServerWeb.Presence.device_presences(device_id) do
        %{metas: [%{connected_at: connected_at} | _]} ->
          connected_at

        _ ->
          nil
      end

    assign(socket, :connected_at, connected_at)
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

  defp connected(%{connected_at: nil} = assigns) do
    ~H"""
    <span class="text-red-500">No</span>
    """
  end

  defp connected(assigns) do
    ~H"""
    <span class="text-green-500">Established <%= display_date_time(@connected_at) %></span>
    """
  end

  defp display_date_time(timestamp) do
    timestamp
    |> DateTime.shift_zone!("Europe/London")
    |> Calendar.strftime("%H:%M:%S %d %b %Y %Z")
  end
end
