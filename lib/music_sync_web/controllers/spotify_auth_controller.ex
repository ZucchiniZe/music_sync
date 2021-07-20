defmodule MusicSyncWeb.SpotifyAuthController do
  use MusicSyncWeb, :controller
  require Logger
  alias MusicSync.Accounts

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
      {:ok, %{body: tokens}} ->
        IO.inspect(tokens)
        authed_client = Spotify.authenticated_client(tokens["access_token"])

        case Spotify.get_user_info(authed_client) do
          {:ok, %{body: %{"error" => %{"message" => message}}}} ->
            Logger.error("unable to get user info due to spotify api error: #{message}")
            text(conn, "failed")

          {:ok, %{body: user_info}} ->
            case Accounts.create_or_update_user_from_spotify_info(user_info, tokens) do
              {:ok, _} ->
                conn
                |> put_session(:user, tokens["refresh_token"])
                |> text("authorized")

              {:error, reason} ->
                IO.inspect(reason)
                Logger.error("unable to create user")
                text(conn, "failed")
            end

          {:error, reason} ->
            IO.inspect(reason)
            Logger.error("unable to get user info")
            text(conn, "failed")
        end

      {:error, reason} ->
        IO.inspect(reason)
        Logger.error("unable to get token")
        text(conn, "failed")
    end
  end
end
