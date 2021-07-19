defmodule MusicSync.Repo do
  use Ecto.Repo,
    otp_app: :music_sync,
    adapter: Ecto.Adapters.Postgres
end
