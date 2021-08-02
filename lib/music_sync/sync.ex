defmodule MusicSync.Sync do
  @moduledoc """
  The module that actually takes all the code from everywhere and starts to sync
  things between places.

  Each function should mark what outside services it interacts with for quick
  reference.
  """
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias MusicSync.Repo

  alias MusicSync.Tracks.Song
  alias MusicSync.Accounts
  alias MusicSync.Accounts.User
  alias Service.{Spotify}

  @doc """
  Queries the spotify api and grabs the lastest tracks for the provided user.
  Transforms the tracks into neatly formed changesets and updated the
  `spotify_latest_track` field on the user to the most recent song.

  Returns a list of properly formatted maps for batch insertion.

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
  Takes a list of song changesets and a user and adds associations between the
  two.

  ## Notes

  implemented using an `Ecto.Multi` transaction, this should be very performant,
  only executing two calls where the info is all batched up. The downside to
  this strategy is that if we have any malformed data, the database rejects the
  changes and errors out.

  outside services:
  - o spotify api
  - o lastfm api
  - x database (two calls!!)
  """
  def add_songs_to_user(songs, %User{} = user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    timestamps = %{inserted_at: now, updated_at: now}

    # genarate the inserted records - assume that these can't be malformed
    songs = Enum.map(songs, &Map.merge(&1, timestamps))
    song_ids = Enum.map(songs, & &1.id)
    user_songs = Enum.map(song_ids, &%{user_id: user.id, song_id: &1})

    Multi.new()
    |> Multi.insert_all(:songs, Song, songs,
      on_conflict: {:replace, [:updated_at]},
      conflict_target: [:id]
    )
    |> Multi.insert_all(:user_songs, "users_songs", user_songs, on_conflict: :nothing)
    |> Repo.transaction()
  end
end
