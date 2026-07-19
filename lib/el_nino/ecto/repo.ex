defmodule ElNino.Repo do
  use Ecto.Repo,
    otp_app: :el_nino,
    adapter: Ecto.Adapters.SQLite3
end
