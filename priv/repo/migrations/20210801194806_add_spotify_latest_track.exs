defmodule MusicSync.Repo.Migrations.AddSpotifyLatestTrack do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :spotify_latest_track, :naive_datetime
    end
  end
end
