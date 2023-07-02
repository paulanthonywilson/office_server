defmodule OfficeServerWeb.BrowserImage.DeviceTokenTest do
  use ExUnit.Case
  alias OfficeServerWeb.BrowserImage.DeviceToken

  test "encodes and decodes the device id" do
    token = DeviceToken.to_token("device-1234")
    assert {:ok, "device-1234"} = DeviceToken.from_token(token)
  end

  test "error is not a real token" do
    assert {:error, :invalid} == DeviceToken.from_token("not a token")
  end

  test "token expires" do
    expired_token =
      "QTEyOEdDTQ.gY0tgjVAPrACkkrmbiKAZtcgoXBbYiw059EsBpWKKVMEusGJQI18YpBN_AQ.Ouao8ABo77U8Zt4d.FlGsH3ee6ci9qDiAfwTH02cxvUOcl6EtAh1Ag2P0FMCC.sLV9ZUTH3OcYGt4017LXdw"

    assert {:error, :expired} == DeviceToken.from_token(expired_token)
  end
end
