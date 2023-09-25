defmodule OfficeServer.Monitoring.MonitoringSupervisor do
  @moduledoc false
  use Supervisor

  @name __MODULE__

  def start_link(_) do
    Supervisor.start_link(__MODULE__, {}, name: @name)
  end

  def init(_) do
    children = [
      OfficeServer.Monitoring.TemperatureMonitor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
