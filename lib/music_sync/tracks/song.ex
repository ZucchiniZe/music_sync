defmodule MusicSync.Tracks.Song do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :string, autogenerate: false}
  schema "songs" do
    field :album, :string
    field :artists, {:array, :string}
    field :name, :string

    many_to_many :users, MusicSync.Accounts.User, join_through: "users_songs"

    timestamps()
  end

  @doc false
  def changeset(song, attrs) do
    song
    |> cast(attrs, [:id, :artists, :name, :album])
    |> validate_required([:id, :artists, :name, :album])
    |> validate_length(:id, is: 22)
  end
end
