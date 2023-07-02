defmodule OfficeServerWeb.OfficeLive do
  alias OfficeServerWeb.BoxComms
  use OfficeServerWeb, :live_view

  use OfficeServer.DeviceData
  alias OfficeServerWeb.BrowserImage
  alias OfficeServerWeb.BrowserImage.DeviceToken

  alias BoxComms.SocketHandler
  require Logger

  def mount(%{"device_id" => device_id}, _session, socket) do
    socket =
      socket
      |> assign(:device_id, device_id)
      |> assign(:temperature, DeviceData.temperature(device_id))
      |> assign_occupation(DeviceData.occupation_status(device_id))
      |> assign_connected(device_id)
      |> assign(:image_token, DeviceToken.to_token(device_id))
      |> assign(:ws_url, BrowserImage.base_ws_url())

    if connected?(socket) do
      DeviceData.subscribe(device_id)
      OfficeServerWeb.Presence.subscribe_presence()
    end

    {:ok, socket}
  end

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <h1 id="head"><%= @device_id %></h1>
    <div class="flex flex-row">
      <div class="grid cols-1 gap-1">
        <.list>
          <:item title="Connected"><.connected connected_at={@connected_at} /></:item>
          <:item title="Temperature"><.temperature temperature={@temperature} /></:item>
          <:item title="Last read">
            <.temperature_timestamp temperature={@temperature} />
          </:item>
          <:item title="Occupation">
            <.occupation occupation={@occupation} />
          </:item>
          <:item title={@occupation_timestamp_title}>
            <.occupation_timestamp occupation={@occupation} />
          </:item>
        </.list>
      </div>
    </div>
    <div class="flex flex-row">
      <.button id="1mincam" class="ml-2 my-6" phx-click="one-minute-cam">One minute camera</.button>
    </div>
    <div class="flex flex-row">
      <div class="grid cols-1 gap-4">
        <img id="cam_img" data-image-token={@image_token} data-ws-url={@ws_url} phx-hook="ImageHook" />
      </div>
    </div>
    """
  end

  def handle_event("one-minute-cam", _, socket) do
    %{assigns: %{device_id: device_id}} = socket
    SocketHandler.send_to_device(device_id, "one-minute-cam")
    {:noreply, socket}
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
    <span class="text-green-500"><%= display_date_time(@connected_at) %></span>
    """
  end

  defp display_date_time(timestamp) do
    timestamp
    |> DateTime.shift_zone!("Europe/London")
    |> Calendar.strftime("%H:%M:%S %d %b %Y %Z")
  end
end
