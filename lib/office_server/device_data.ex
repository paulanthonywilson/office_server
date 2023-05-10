defmodule OfficeServer.DeviceData do
  @moduledoc """
  Testing seam for device data
  """

  @doc """
  Receive occupation and temperature events related to a device
  """
  @callback subscribe(device_id :: String.t()) :: :ok

  @doc """
  Last device temperature
  """
  @callback temperature(device_id :: String.t()) ::
              :unknown | {temperature :: Decimal.t(), timestamp :: DateTime.t()}

  @callback occupation_status(device_id :: String.t()) ::
              :unknown | {:occupied | :unoccupied, timestamp :: DateTime.t()}

  defmacro __using__(_) do
    impl =
      if OfficeServer.CompilationEnv.testing?(),
        do: MockDeviceData,
        else: OfficeServer.RealDeviceData

    quote do
      alias unquote(impl), as: DeviceData
    end
  end
end
