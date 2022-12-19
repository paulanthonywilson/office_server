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

  defp auth_username do
    Keyword.fetch!(config(), :username)
  end

  defp auth_password do
    Keyword.fetch!(config(), :password)
  end

  defp config do
    Application.fetch_env!(:office_server, :auth)
  end
end
