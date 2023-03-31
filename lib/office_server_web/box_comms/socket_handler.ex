defmodule OfficeServerWeb.BoxComms.SocketHandler do
  @moduledoc """
  Handles messages from a (the) security box.
  """

  @behaviour FedecksServer.FedecksHandler
  alias OfficeServer.Authentication

  alias FedecksServer.FedecksHandler
  alias Phoenix.PubSub
  require Logger

  @impl FedecksHandler
  def authenticate?(%{"username" => username, "password" => password}) do
    IO.inspect(:authenticate)

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
end
