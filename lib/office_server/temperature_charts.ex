defmodule OfficeServer.TemperatureCharts do
  @moduledoc """
  VegaLite friendly data for historic temperatures
  """

  @doc """
  Convert tuple list of {temperature, date_time} to a map of
  temperatures and date times.
  """

  @spec historic_temperatures_to_vega_lite_friendly(
          list({temperature :: Decimal.t(), date_time :: DateTime.t()}),
          opts :: keyword()
        ) :: VegaLite.t()
  def historic_temperatures_to_vega_lite_friendly(temperatures, opts \\ [width: 600, height: 800]) do
    {temperatures, date_times} = Enum.unzip(temperatures)

    VegaLite.new(opts)
    |> VegaLite.data_from_values(%{temperatures: temperatures, date_times: date_times})
    |> VegaLite.mark(:line, point: true)
    |> VegaLite.encode_field(:x, "date_times",
      type: :temporal,
      title: "",
      axis: [format: "%H:%M %d %b %y", label_angle: 50]
    )
    |> VegaLite.encode_field(:y, "temperatures", type: :quantitative, title: "℃")
  end
end
