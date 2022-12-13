defmodule OfficeServer.Repo do
  use Ecto.Repo,
    otp_app: :office_server,
    adapter: Ecto.Adapters.Postgres
end
