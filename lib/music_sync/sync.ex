defmodule MusicSync.Sync do
  @moduledoc """
  The module that actually takes all the code from everywhere and starts to sync
  things between places.

  Each function should mark what outside services it interacts with for quick
  reference.
  """
  import Ecto.Query, warn: false
  alias MusicSync.Repo

  alias MusicSync.Tracks.Song
  alias MusicSync.Accounts
  alias MusicSync.Accounts.User
  alias Service.{Spotify}

  @doc """
  Queries the spotify api and grabs the lastest tracks for the provided user.
  Transforms the tracks into neatly formed changesets and updated the
  `spotify_latest_track` field on the user to the most recent song.

  outside services:
  - x spotify api
  - o lastfm api
  - x database (single call)
  """
  def saved_songs_from_spotify_for_user(%User{} = user) do
    {:ok, songs} =
      user
      |> Spotify.authenticated_client()
      |> Spotify.saved_tracks(user.spotify_latest_track)

    {:ok, _} = Accounts.update_user(user, %{spotify_latest_track: List.first(songs)["added_at"]})
    Enum.map(songs, &Song.parse_spotify_song/1)
  end

  @doc """
  Takes a list of song changesets and a user and attaches them together using
  the database.

  outside services:
  - o spotify api
  - o lastfm api
  - x database (many call)
  """
  def add_songs_to_user(songs, %User{} = user) do
    inserted_songs = Enum.map(songs, &Repo.insert!(&1, on_conflict: :nothing))

    user
    |> Repo.preload(:songs)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_assoc(:songs, inserted_songs)
    |> Repo.update!()
  end
end
