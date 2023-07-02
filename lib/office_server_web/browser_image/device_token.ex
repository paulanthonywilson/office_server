defmodule OfficeServerWeb.BrowserImage.DeviceToken do
  @moduledoc """
  Token for securely passing the device id to the brower image socket
  """
  alias Plug.Crypto
  @ten_minutes 60 * 10
  @expiry @ten_minutes
  @refresh_milliseconds Integer.floor_div(@expiry, 2) * 1_000

  @doc """
  Suggested refresh rate - half the time of the expiry
  """
  @spec refresh_milliseconds :: pos_integer()
  def refresh_milliseconds, do: @refresh_milliseconds

  @doc """
  Encodes the device id as a secure token
  """
  def to_token(device_id) do
    Crypto.encrypt(secret(), salt(), device_id)
  end

  @doc """
  Decodes the device id from the token
  """
  def from_token(token) do
    Crypto.decrypt(secret(), salt(), token, max_age: @expiry)
  end

  defp config do
    Application.fetch_env!(:office_server, __MODULE__)
  end

  defp salt, do: Keyword.fetch!(config(), :salt)
  defp secret, do: Keyword.fetch!(config(), :secret)
end
