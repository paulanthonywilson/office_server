defmodule OfficeServer.Devices do
  @moduledoc """
  The Devices context.
  """

  import Ecto.Query, warn: false
  alias OfficeServer.Repo

  alias OfficeServer.Devices.Device

  @doc """
  Returns the list of devices.

  ## Examples

      iex> list_devices()
      [%Device{}, ...]

  """
  def list_devices do
    Repo.all(Device)
  end

  @doc """
  Gets a single device.

  Raises `Ecto.NoResultsError` if the Device does not exist.

  ## Examples

      iex> get_device!(123)
      %Device{}

      iex> get_device!(456)
      ** (Ecto.NoResultsError)

  """
  def get_device!(id), do: Repo.get!(Device, id)

  @doc """
  Creates a device.

  ## Examples

      iex> create_device(%{field: value})
      {:ok, %Device{}}

      iex> create_device(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_device(attrs \\ %{}) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns the device with the given device id
  """
  @spec by_device_id(String.t()) :: {:ok, Device.t()} | {:error, :notfound}
  def by_device_id(device_id) do
    case Repo.one(from d in Device, where: d.device_id == ^device_id) do
      nil -> {:error, :notfound}
      device -> {:ok, device}
    end
  end

  @doc """
  Deletes a device.

  ## Examples

      iex> delete_device(device)
      {:ok, %Device{}}

      iex> delete_device(device)
      {:error, %Ecto.Changeset{}}

  """
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end
end
