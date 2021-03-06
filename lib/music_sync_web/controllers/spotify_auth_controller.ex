defmodule MusicSyncWeb.SpotifyAuthController do
  use MusicSyncWeb, :controller
  require Logger
  alias MusicSync.Accounts
  alias MusicSyncWeb.UserAuth
  alias Service.Spotify

  @client_id Application.compile_env!(:music_sync, [MusicSync.Spotify, :client_id])

  @doc """
  Redirect to spotify login page with the proper url
  """
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

  @doc """
  Login callback for spotify, gives us a `code` that we need to then verify with
  them.
  """
  def authorize(conn, %{"error" => _, "error_description" => desc}) do
    info_str = "error encountered with spotify login: #{desc}"
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

    with {:ok, %{status: 200, body: tokens}} <- Spotify.get_token(post_params),
         authed_client <- Spotify.authenticated_client(tokens["access_token"]),
         {:ok, %{status: 200, body: user_info}} <- Spotify.get_user_info(authed_client),
         {:ok, user} <- Accounts.create_or_update_user_from_spotify_info(user_info, tokens) do
      conn
      |> UserAuth.log_in_user(user)
    else
      {:ok, resp} ->
        Logger.error("#{resp.url} failed with a #{resp.status} due to #{get_error(resp)}")

        conn
        |> put_flash(:error, "Failed to log in, please try again")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.error("unable to create user #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to log in, please try again")
        |> redirect(to: "/")
    end
  end

  def refresh(conn, _params) do
    conn.assigns[:current_user] |> Accounts.refresh_spotify_token()

    conn
    |> put_flash(:info, "Refreshed spotify token")
    |> redirect(to: "/")
  end

  # When the request succeeds but errors on spotify's end. There are two different
  # data formats for letting us know that there is an error, this runs over both
  # as a generic and returns an error reason
  defp get_error(%{body: %{"error" => err_map}}) when is_map(err_map), do: err_map["message"]
  defp get_error(%{body: %{"error" => message}}) when is_binary(message), do: message
  defp get_error(%{body: message}) when is_binary(message), do: message
end
