defmodule OfficeServer.TemperaturesTest do
  use OfficeServer.DataCase

  alias OfficeServer.Temperatures
  alias OfficeServer.Temperatures.Temperature

  @a_date_time ~U[2023-11-14 12:51:11Z]

  describe "recording temperatures for a device" do
    test "inserts correct data" do
      assert :ok = Temperatures.record("device12", "11.25", @a_date_time)

      assert [
               %Temperature{
                 device_id: "device12",
                 temperature: temperature,
                 recorded_time: @a_date_time
               }
             ] =
               Repo.all(Temperature)

      assert Decimal.eq?("11.25", temperature)
    end
  end

  describe "device temperatures" do
    test "returns only the temperatures for a device" do
      Temperatures.record("device1", "10", @a_date_time)
      Temperatures.record("device2", "20", @a_date_time)

      assert [{temperature1, @a_date_time}] = Temperatures.device_temperatures("device1")
      assert Decimal.eq?("10", temperature1)
    end

    test "is ordered descending by recorded at" do
      setup_some_temperatures(0..2)

      assert ["15.2", "15.1", "15.0"] ==
               "device0"
               |> Temperatures.device_temperatures()
               |> Enum.map(fn {t, _} -> Decimal.to_string(t) end)
    end

    test "can limit results" do
      setup_some_temperatures(0..5)

      assert ["15.5", "15.4"] ==
               "device0"
               |> Temperatures.device_temperatures(2)
               |> Enum.map(fn {t, _} -> Decimal.to_string(t) end)
    end

    defp setup_some_temperatures(range) do
      for i <- range do
        temperature = Decimal.add(15, "0.#{i}")
        datetime = DateTime.add(@a_date_time, i)
        Temperatures.record("device0", temperature, datetime)
      end
    end
  end
end
