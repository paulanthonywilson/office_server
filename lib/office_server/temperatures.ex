defmodule OfficeServer.Temperatures do
  @moduledoc """
  Context for recording and reading back temperatures
  """

  import Ecto.Query, warn: false
  alias OfficeServer.Repo

  alias OfficeServer.Temperatures.Temperature

  @doc """
  Records the temperature for the device
  """
  @spec record(
          device_id :: String.t(),
          temperture :: Decimal.decimal(),
          temperature_time :: DateTime.t()
        ) :: :ok
  def record(device_id, temperature, temperature_time) do
    %Temperature{}
    |> Temperature.changeset(%{
      device_id: device_id,
      temperature: temperature,
      recorded_time: temperature_time
    })
    |> Repo.insert!()

    :ok
  end

  @doc """
  Returns the temperatures and recorded time for a device, as a list of two element tuples
  (temperature and time). It is ordered descending by the recorded time the temperature was
  taken.
  """
  @spec device_temperatures(device_id :: String.t()) ::
          list({temperature :: Decimal.t(), recorded_time :: DateTime.t()})
  def device_temperatures(device_id) do
    device_id
    |> temperature_query()
    |> Repo.all()
  end

  @doc """
  Returns the temperatures and time, as per `device_temperatures/1`, but limited to
  a maximum number of values as defined by limit
  """
  @spec device_temperatures(device_id :: String.t(), limit :: pos_integer()) ::
          list({temperature :: Decimal.t(), recorded_time :: DateTime.t()})
  def device_temperatures(device_id, limit) do
    q = temperature_query(device_id)

    Repo.all(from t in q, limit: ^limit)
  end

  defp temperature_query(device_id) do
    from(t in Temperature,
      where: t.device_id == ^device_id,
      order_by: [desc: t.recorded_time],
      select: {t.temperature, t.recorded_time}
    )
  end
end
