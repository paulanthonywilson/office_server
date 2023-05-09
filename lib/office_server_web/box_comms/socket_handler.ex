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
  def connection_established(device_id) do
    {:ok, _} =
      OfficeServerWeb.Presence.track(self(), @presence_topic, device_id, %{
        connected_at: DateTime.utc_now(),
        pid: self()
      })

    :ok
  end

  def presence_topic, do: @presence_topic
end
