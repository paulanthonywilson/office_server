defmodule OfficeServer.TemperatureChartsTest do
  use OfficeServer.DataCase, async: true

  alias OfficeServer.TemperatureCharts

  describe "datetimes and temperatures" do
    test "returns date friendly versions" do
      # assert %{
      #          temperatures: [temp1, temp2],
      #          date_times: [~U[2021-01-02 00:00:00Z], ~U[2021-01-01 00:00:00Z]]
      #        }

      %{spec: %{"data" => %{"values" => [latest, first]}}} =
        TemperatureCharts.historic_temperatures_to_vega_lite_friendly([
          {Decimal.new("11"), ~U[2021-01-02 00:00:00Z]},
          {Decimal.new("10"), ~U[2021-01-01 00:00:00Z]}
        ])

      assert %{"date_times" => ~U[2021-01-02 00:00:00Z], "temperatures" => latest_t} = latest
      assert %{"date_times" => ~U[2021-01-01 00:00:00Z], "temperatures" => first_t} = first

      assert Decimal.eq?("11", latest_t)
      assert Decimal.eq?("10", first_t)
    end
  end
end
