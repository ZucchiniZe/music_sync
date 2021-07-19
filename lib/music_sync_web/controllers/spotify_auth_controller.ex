defmodule MusicSyncWeb.SpotifyAuthController do
  use MusicSyncWeb, :controller

  @redirect_uri "http://localhost:4000/spotify/authorize" |> URI.encode()
  @client_id "20cf26fd82a84e02a34e9cfa891d29d6"
  @client_secret "2a7f0ceb011d43a0bd249acbf0621991"

  def login(conn, _params) do
    redirect(conn, external: build_spotify_auth_url())
  end

  def authorize(conn, params) do
    # TODO: create user account here

    # TODO: error handling for if `params["error"]` exists
    post_params = [
      code: params["code"],
      grant_type: "authorization_code",
      redirect_uri: @redirect_uri,
      client_id: @client_id,
      client_secret: @client_secret
    ]

    client = Spotify.login_client()
    # TODO: error handling for bad token
    {:ok, resp: %{body: body}} = Spotify.get_token(client, post_params)

    IO.inspect(body)

    text(conn, "authorized")
  end

  def build_spotify_auth_url do
    scope =
      ["user-read-email", "user-library-read", "user-library-modify"]
      |> Enum.join(" ")
      |> URI.encode()

    "https://accounts.spotify.com/authorize?client_id=#{@client_id}" <>
      "&response_type=code&scope=#{scope}&redirect_uri=#{@redirect_uri}"
  end
end
