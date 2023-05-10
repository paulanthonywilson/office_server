defmodule OfficeServer.RealClock do
  @moduledoc """
  Provices current time
  """

  @behaviour OfficeServer.Clock

  def utc_now, do: DateTime.utc_now()
end
