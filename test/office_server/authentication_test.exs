defmodule OfficeServer.AuthenticationTest do
  use ExUnit.Case
  alias OfficeServer.Authentication

  test "authenticates" do
    assert {:ok, _user_id} = Authentication.authenticate("test_user", "test_password")
    assert :error = Authentication.authenticate("wrong_user", "test_password")
    assert :error = Authentication.authenticate("test_user", "wrong_password")
  end
end
