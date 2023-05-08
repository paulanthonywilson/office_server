defmodule OfficeServerWeb.OfficeListLive do
  use OfficeServerWeb, :live_view

  def mount(_params, _sess, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    List of connected
    """
  end
end
