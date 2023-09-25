defmodule OfficeServer.Monitoring.TemperatureMonitorTest do
  use OfficeServer.DataCase, async: true

  import Mox

  alias OfficeServer.Monitoring.TemperatureMonitor
  alias OfficeServer.{AllDevicePubSub, Repo, Temperatures}

  setup :verify_on_exit!

  @a_time1 ~U[2013-10-09 02:01:00Z]
  @a_time2 ~U[2022-10-09 02:01:00Z]
  @device1 "t_monitor_device1"
  @device2 "t_monitor_device2"

  setup do
    Temperatures.record(@device1, "19.5", @a_time1)
    name = :"#{:rand.uniform()}.#{inspect(self())}"
    {:ok, pid} = start_supervised({TemperatureMonitor, name: name})

    allow(MockClock, self(), pid)
    stub(MockClock, :utc_now, fn -> @a_time2 end)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), pid)

    {:ok, pid: pid}
  end

  test "records a new temperature if non already recorded by the process", ctx do
    AllDevicePubSub.broadcast_office_event(:device_msg, @device1, %{
      "temperature" => "20.2"
    })

    ensure_monitor_processes_messages(ctx)

    assert ["20.2", "19.5"] = just_recorded_temperature_strings(@device1)
  end

  test "records new temperatures as long as it is 0.1 degrees or more different than the last recorded",
       ctx do
    notify_of_some_temperatures(@device2, ["20.1", "20.2", "20.301"], ctx)

    assert ["20.301", "20.2", "20.1"] == just_recorded_temperature_strings(@device2)
  end

  test "does not record temperature if it is less than 0.1 degree different to the last recorded",
       ctx do
    notify_of_some_temperatures(@device2, ["20.1", "20.1", "20.001", "20.199"], ctx)
    assert ["20.1"] == just_recorded_temperature_strings(@device2)
  end

  test "one device temperature does not interfere with another", ctx do
    AllDevicePubSub.broadcast_office_event(:device_msg, @device1, %{"temperature" => "20.25"})
    AllDevicePubSub.broadcast_office_event(:device_msg, @device2, %{"temperature" => "20.25"})
    ensure_monitor_processes_messages(ctx)
    assert ["20.25"] == just_recorded_temperature_strings(@device2)
  end

  defp notify_of_some_temperatures(device_id, temperatures, ctx) do
    temperatures
    |> Enum.with_index()
    |> Enum.each(fn {t, i} ->
      stub(MockClock, :utc_now, fn -> DateTime.add(@a_time2, i) end)

      AllDevicePubSub.broadcast_office_event(:device_msg, device_id, %{
        "temperature" => t
      })

      ensure_monitor_processes_messages(ctx)
      :ok
    end)
  end

  defp just_recorded_temperature_strings(device_id) do
    for({t, _} <- Temperatures.device_temperatures(device_id), do: Decimal.to_string(t))
  end

  defp ensure_monitor_processes_messages(%{pid: pid}) do
    :sys.get_state(pid)
  end
end
