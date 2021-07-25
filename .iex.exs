alias MusicSync.Accounts

me = Accounts.get_user_by_id!(1)

spotify_client = me |> Spotify.authenticated_client()
lastfm_client = me |> Lastfm.authenticated_client()
