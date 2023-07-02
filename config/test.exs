import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :office_server, OfficeServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "office_server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :office_server, OfficeServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "NgQrZLLPnHMc0M60pNouKNKg9t2fiOvDLv1yLGECBw/MfgOESQaH4+LtyQcjRMsJ",
  server: false

# In test we don't send emails.
config :office_server, OfficeServer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :office_server, :auth, username: "test_user", password: "test_password"

config :office_server, OfficeServerWeb.BrowserImage.DeviceToken,
  salt: "NU14g1dmGVXk3tQxWvwINgd38638V+cctSbz59ubnNuYPf+RHOrGOcBzzki2NSX3",
  secret: "Cb8/u4FZ3M1hSXC2h5FqmWRYyClzkajswjm2AhhrMX2XN1zYSR4usWPHPFRp0kEq"
