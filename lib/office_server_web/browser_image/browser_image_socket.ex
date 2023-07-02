defmodule OfficeServerWeb.BrowserImage.BrowserImageSocket do
  @moduledoc """
  Socket to server images to the browser
  """
  @behaviour Phoenix.Socket.Transport

  alias OfficeServer.AllDevicePubSub
  alias OfficeServerWeb.BrowserImage.DeviceToken

  @impl Phoenix.Socket.Transport
  def child_spec(_opts) do
    %{id: __MODULE__, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @impl Phoenix.Socket.Transport
  def connect(%{params: %{"token" => token}}) do
    case DeviceToken.from_token(token) do
      {:ok, device_id} ->
        {:ok, %{device_id: device_id, refresh: DeviceToken.refresh_milliseconds()}}

      {:error, :expired} ->
        {:ok, :expired_token}

      _err ->
        :error
    end
  end

  @impl Phoenix.Socket.Transport
  def init(:expired_token) do
    send(self(), :expired_token)
    {:ok, :expired_token}
  end

  def init(%{device_id: device_id, refresh: refresh} = state) do
    AllDevicePubSub.subscribe_to_images(device_id)
    Process.send_after(self(), :refresh_token, refresh)
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_info(:expired_token, :expired_token) do
    send(self(), :close_socket)
    {:push, {:text, "expired_token"}, :expired_token}
  end

  def handle_info(:close_socket, state) do
    {:stop, :closed, state}
  end

  def handle_info(:refresh_token, %{device_id: device_id, refresh: refresh} = state) do
    Process.send_after(self(), :refresh_token, refresh)
    {:push, {:text, "token:" <> DeviceToken.to_token(device_id)}, state}
  end

  def handle_info({:image, device_id, image}, %{device_id: device_id} = state) do
    {:push, {:binary, image}, state}
  end

  @impl Phoenix.Socket.Transport
  def handle_in(_, state) do
    {:ok, state}
  end

  @impl Phoenix.Socket.Transport
  def terminate(_reason, _state) do
    :ok
  end
end
