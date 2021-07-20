defmodule MusicSyncWeb.SpotifyAuthController do
  use MusicSyncWeb, :controller
  require Logger

  @client_id Application.get_env(:music_sync, MusicSync.Spotify)[:client_id]

  def login(conn, _params) do
    redirect_uri =
      Routes.spotify_auth_url(MusicSyncWeb.Endpoint, :authorize)
      |> URI.encode()

    scope =
      ["user-read-email", "user-library-read", "user-library-modify"]
      |> Enum.join(" ")
      |> URI.encode()

    url =
      "https://accounts.spotify.com/authorize?client_id=#{@client_id}" <>
        "&response_type=code&scope=#{scope}&redirect_uri=#{redirect_uri}"

    redirect(conn, external: url)
  end

  def authorize(conn, %{"error" => _, "error_description" => desc}) do
    info_str = "error encountered on spotify's end: #{desc}"
    Logger.error(info_str)
    text(conn, info_str)
  end

  def authorize(conn, params) do
    post_params = [
      code: params["code"],
      grant_type: "authorization_code",
      redirect_uri:
        Routes.spotify_auth_url(MusicSyncWeb.Endpoint, :authorize)
        |> URI.encode()
    ]

    case Spotify.login_client() |> Spotify.get_token(post_params) do
      {:ok, %{body: body}} ->
        IO.inspect(body)
        # TODO: create user account here
        authed_client = Spotify.authenticated_client(body["access_token"])

        Spotify.get_user_info(authed_client) |> IO.inspect()

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("unable to get token")
    end

    text(conn, "authorized")
  end
end
