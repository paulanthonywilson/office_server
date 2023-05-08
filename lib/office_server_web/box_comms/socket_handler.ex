defmodule OfficeServerWeb.BoxComms.SocketHandler do
  @moduledoc """
  Handles messages from a (the) security box.
  """

  @behaviour FedecksServer.FedecksHandler
  alias OfficeServer.Authentication

  alias FedecksServer.FedecksHandler
  alias Phoenix.PubSub

  @presence_topic to_string(__MODULE__)

  require Logger

  def subscribe_presence do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, @presence_topic)
  end

  @impl FedecksHandler
  def authenticate?(%{"username" => username, "password" => password}) do
    case Authentication.authenticate(username, password) do
      {:ok, _} -> true
      _ -> false
    end
  end

  def authenticate?(_), do: false

  @impl FedecksHandler
  def otp_app, do: :office_server

  @impl FedecksHandler
  def handle_in(device_id, message) do
    PubSub.broadcast!(OfficeServer.PubSub, "office_events", {"office_events", device_id, message})
  end

  @impl FedecksHandler
  def connection_established(_device_id) do
    send(self(), :track_presence)
    :ok
  end

  @impl FedecksHandler
  def handle_info(device_id, :track_presence) do
    @presence_topic
    |> OfficeServerWeb.Presence.list()
    |> Map.get(device_id)
    |> case do
      nil ->
        OfficeServerWeb.Presence.track(self(), @presence_topic, device_id, %{
          connected_at: DateTime.utc_now(),
          pid: self()
        })

      %{metas: metas} ->
        # We have some zombie sockets. Shut them down now and retry in a few
        for %{pid: pid} <- metas do
          send(pid, :please_stop)
        end

        Process.send_after(self(), :track_presence, 50)
    end

    :ok
  end

  def handle_info(device_id, :please_stop) do
    {:stop, "#{device_id} zombie socket stopping"}
  end

  def presence_topic, do: @presence_topic
end
