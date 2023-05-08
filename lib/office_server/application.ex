defmodule OfficeServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OfficeServerWeb.Telemetry,
      OfficeServer.Repo,
      {Phoenix.PubSub, name: OfficeServer.PubSub},
      {Finch, name: OfficeServer.Finch},
      OfficeServerWeb.Endpoint,
      OfficeServerWeb.Presence
    ]

    opts = [strategy: :one_for_one, name: OfficeServer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    OfficeServerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
