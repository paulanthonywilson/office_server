defmodule OfficeServerWeb.OfficeLive do
  use OfficeServerWeb, :live_view

  def mount(%{"device_id" => device_id}, _session, socket) do
    socket = assign(socket, device_id: device_id)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <h1 id="head"><%= @device_id %></h1>
    """
  end
end
