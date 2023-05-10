defmodule OfficeServer.DeviceData do
  @moduledoc """
  Holds data from the devices
  """
  use GenServer

  use OfficeServer.Clock
  alias OfficeServer.AllDevicePubSub

  @name __MODULE__

  def start_link(opts) do
    name = Keyword.get(opts, :name, @name)
    GenServer.start_link(__MODULE__, name, name: name)
  end

  def subscribe(device_id) do
    Phoenix.PubSub.subscribe(OfficeServer.PubSub, topic(device_id))
  end

  def temperature(name \\ @name, device) do
    lookup(name, device, :temperature)
  end

  def occupation_status(name, device) do
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
        {"office_events", :device_message, device, event},
        %{table: table} = state
      ) do
    handle_device_event(device, table, event)
    {:noreply, state}
  end

  defp handle_device_event(device, table, %{"temperature" => temperature}) do
    :ets.insert(table, {{device, :temperature}, {temperature, Clock.utc_now()}})
    broadcast(device, {:device_data, device, :temperature, temperature})
  end

  defp handle_device_event(device, table, %{"occupied" => timestamp}) do
    change_occupation(device, table, :occupied, timestamp)
  end

  defp handle_device_event(device, table, %{"unoccupied" => timestamp}) do
    change_occupation(device, table, :unoccupied, timestamp)
  end

  defp handle_device_event(_device, _table, _event), do: :ok

  defp change_occupation(device, table, direction, timestamp) do
    status = {direction, timestamp}
    :ets.insert(table, {{device, :occupation}, status})
    broadcast(device, {:device_data, device, :occupation, status})
  end

  defp broadcast(device, message) do
    Phoenix.PubSub.broadcast(OfficeServer.PubSub, topic(device), message)
  end

  defp table_name(name) do
    :"table_#{name}"
  end

  defp topic(device_id) do
    "#{__MODULE__}.#{device_id}"
  end
end
