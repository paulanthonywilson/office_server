defmodule OfficeServer.Clock do
  @moduledoc """
  Testing seam for the current time
  """

  @callback utc_now :: DateTime.utc_now()

  defmacro __using__(_) do
    implementation =
      if OfficeServer.CompilationEnv.testing?(), do: MockClock, else: OfficeServer.RealClock

    quote do
      alias unquote(implementation), as: Clock
    end
  end
end
