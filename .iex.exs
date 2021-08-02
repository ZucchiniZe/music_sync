alias MusicSync.{Repo, Sync, Accounts, Tracks}
alias Service.{Lastfm, Spotify}

me = Accounts.get_user_by_id!(1) |> Repo.preload(:songs)

spotify_client = me |> Spotify.authenticated_client()
lastfm_client = me |> Lastfm.authenticated_client()
