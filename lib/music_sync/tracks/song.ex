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

  def parse_spotify_song(api_response) do
    track = api_response["track"]
    album = get_in(track, ["album", "name"])
    artists = Enum.map(track["artists"], & &1["name"])
    added_at = api_response["added_at"] |> NaiveDateTime.from_iso8601!()

    %{
      id: track["id"],
      name: track["name"],
      album: album,
      artists: artists,
      added_at: added_at
    }
  end
end
