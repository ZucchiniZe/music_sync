defmodule MusicSync.Repo.Migrations.CreateUsersSongsTable do
  use Ecto.Migration

  def change do
    create table(:users_songs, primary_key: false) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :song_id, references(:songs, on_delete: :delete_all, type: :"varchar(22)"), primary_key: true
    end

    create index(:users_songs, [:user_id])
    create index(:users_songs, [:song_id])
  end
end
