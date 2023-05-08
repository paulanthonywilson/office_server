defmodule OfficeServer.Authentication do
  @moduledoc """
  Authenticates. Basic authentication, at least just now, with a single username and password. For the feels
  the user id `1` is used.

  """

  alias Plug.Crypto

  def authenticate(username, password) do
    if Crypto.secure_compare(username, auth_username()) &&
         Crypto.secure_compare(password, auth_password()) do
      {:ok, 1}
    else
      :error
    end
  end

  @spec auth_username :: String.t()
  def auth_username do
    Keyword.fetch!(config(), :username)
  end

  @spec auth_password :: String.t()
  def auth_password do
    Keyword.fetch!(config(), :password)
  end

  defp config do
    Application.fetch_env!(:office_server, :auth)
  end
end
