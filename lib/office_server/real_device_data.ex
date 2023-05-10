defmodule OfficeServer.RealDeviceData do
  @moduledoc """
  Holds data from the devices
  """
  use GenServer

  use OfficeServer.Clock

  alias OfficeServer.{AllDevicePubSub, DeviceData}
  @behaviour DeviceData

  @name __MODULE__

  def start_link(opts) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  @impl DeviceData
  def subscribe(device_id) do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, topic(device_id))
  end

  @impl DeviceData
  def temperature(name \\ @name, device) do
    lookup(name, device, :temperature)
  end

  @impl DeviceData
  def occupation_status(name \\ @name, device) do
    lookup(name, device, :occupation)
  end

  defp lookup(name, device, key) do
    name
    |> table_name()
    |> :ets.lookup({device, key})
    |> case do
      [{{^device, ^key}, {temperature, time}}] ->
        {temperature, time}

      _ ->
        :unknown
    end
  end

  @impl GenServer
  def init(name) do
    table = name |> table_name() |> :ets.new([:named_table])
    AllDevicePubSub.subscribe_office_events()
    {:ok, %{table: table}}
  end

  @impl GenServer
  def handle_info(
        {"office_events", :device_msg, device, event},
        %{table: table} = state
      ) do
    handle_device_event(device, table, event)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  defp handle_device_event(device, table, %{"temperature" => temperature}) do
    temperature_value = {temperature, Clock.utc_now()}
    # :ets.insert(table, {{device, :temperature}, temperature_value})
    insert_and_broadcast(device, table, :temperature, temperature_value)
    # broadcast(device, {:device_data, device, :temperature, temperature_value})
  end

  defp handle_device_event(device, table, %{"occupied" => timestamp}) do
    insert_and_broadcast(device, table, :occupation, {:occupied, timestamp})
  end

  defp handle_device_event(device, table, %{"unoccupied" => timestamp}) do
    insert_and_broadcast(device, table, :occupation, {:unoccupied, timestamp})
  end

  defp handle_device_event(_device, _table, _event) do
  end

  defp insert_and_broadcast(device, table, type, value) do
    :ets.insert(table, {{device, type}, value})
    broadcast(device, {:device_data, device, type, value})
  end

  defp broadcast(device, event) do
    Phoenix.PubSub.broadcast(OfficeServer.PubSub, topic(device), event)
  end

  defp table_name(name) do
    :"table_#{name}"
  end

  defp topic(device_id) do
    "#{__MODULE__}.#{device_id}"
  end
end
