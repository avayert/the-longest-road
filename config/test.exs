import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# config :catan_game, Catan.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "catan_game_test#{System.get_env("MIX_TEST_PARTITION")}",
#   pool: Ecto.Adapters.SQL.Sandbox,
#   pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :catan_game, CatanWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "7vdDP5nUx93xN5kPSarY6wzvkT1bIeYSl7vwiYVPhYgGFrhuGVJkF/3WV42thbi+",
  server: false

# In test we don't send emails.
config :catan_game, Catan.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
