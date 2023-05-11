defmodule TearDownPresence do
  def tear_down do
    for pid <- OfficeServerWeb.Presence.fetchers_pids() do
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, _, _, _} -> pid
      after
        1000 -> raise "Presence pid did not exit"
      end
    end
  end
end
