defmodule Catan.Repo do
  use Ecto.Repo,
    otp_app: :catan_game,
    adapter: Ecto.Adapters.Postgres
end
