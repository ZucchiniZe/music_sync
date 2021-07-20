defmodule MusicSync.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string
      add :name, :string
      add :username, :string
      add :spotify_access_token, :string
      add :spotify_token_expiry, :naive_datetime
      add :spotify_refresh_token, :string
      add :lastfm_auth_token, :string
      add :lastfm_session_key, :string

      timestamps()
    end

  end
end
