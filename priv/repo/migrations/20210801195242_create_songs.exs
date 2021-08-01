defmodule MusicSync.Repo.Migrations.CreateSongs do
  use Ecto.Migration

  def change do
    create table(:songs, primary_key: false) do
      add :id, :string, size: 22, primary_key: true
      add :artists, {:array, :string}
      add :name, :string
      add :album, :string

      timestamps()
    end
  end
end
