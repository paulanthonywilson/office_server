defmodule OfficeServer.Monitoring.TemperatureMonitor do
  @moduledoc """
  Listens for device temperature updates and records them in the database if
  the difference is equal to or greater than 0.1 degrees C than the last update
  to be recorded.

  This will always record the first temperature after the process has started.
  """
  use GenServer
  use OfficeServer.Clock
  alias OfficeServer.{AllDevicePubSub, Temperatures}

  @name __MODULE__

  def start_link(opts) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def init(name) do
    AllDevicePubSub.subscribe_office_events()
    ets_temperatures = :ets.new(:"last_temperature_#{name}", [])

    {:ok, %{ets_temperatures: ets_temperatures}}
  end

  def handle_info(
        {"office_events", :device_msg, device_id, message},
        %{ets_temperatures: ets_temperatures} = state
      ) do
    handle_device_message(device_id, message, ets_temperatures)
    {:noreply, state}
  end

  defp handle_device_message(device_id, %{"temperature" => temperature}, ets_temperatures) do
    if should_record_temperature?(ets_temperatures, device_id, temperature) do
      record_temperature(device_id, temperature, ets_temperatures)
    end
  end

  defp handle_device_message(_, _, _), do: :ok

  defp should_record_temperature?(ets_temperatures, device_id, temperature) do
    ets_temperatures
    |> :ets.lookup(device_id)
    |> should_record_temperature?(temperature)
  end

  defp should_record_temperature?([], _), do: true

  defp should_record_temperature?([{_device_id, last_temperature}], temperature) do
    :lt !=
      last_temperature
      |> Decimal.sub(temperature)
      |> Decimal.abs()
      |> Decimal.compare("0.1")
  end

  defp record_temperature(device_id, temperature, ets_temperatures) do
    Temperatures.record(device_id, temperature, Clock.utc_now())
    :ets.insert(ets_temperatures, {device_id, temperature})
  end
end
