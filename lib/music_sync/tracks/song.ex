defmodule MusicSync.Tracks.Song do
  @moduledoc false
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

  @doc """
  Takes a big spotify [TrackObject][trackobject] and turns it into a neat map

  [trackobject]: https://developer.spotify.com/documentation/web-api/reference/#object-trackobject
  """
  def parse_spotify_song(api_response) do
    track = api_response["track"]

    %{
      id: track["id"],
      name: track["name"],
      album: get_in(track, ["album", "name"]),
      artists: Enum.map(track["artists"], & &1["name"])
    }
  end
end
