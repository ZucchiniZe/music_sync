defmodule MusicSync.Repo.Migrations.ModifyLastfmInfoOnUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      remove :lastfm_auth_token
      add :lastfm_username, :string
    end
  end
end
