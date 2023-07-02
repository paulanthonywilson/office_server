defmodule OfficeServerWeb.BrowserImage do
  @moduledoc """
  Provides `base_ws_url/1`
  """

  def base_ws_url do
    base_ws_url(OfficeServerWeb.Endpoint.static_url())
  end

  def base_ws_url(static_url) do
    "#{String.replace_leading(static_url, "http", "ws")}/images/"
  end
end
