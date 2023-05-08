defmodule OfficeServerWeb.Presence do
  use Phoenix.Presence, otp_app: :office_server, pubsub_server: OfficeServer.PubSub
end
