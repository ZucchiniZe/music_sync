defmodule MusicSyncWeb.LastfmAuthController do
  use MusicSyncWeb, :controller
  require Logger
  alias MusicSync.Accounts

  @client_id Application.get_env(:music_sync, MusicSync.Lastfm)[:client_id]

  @doc """
  Redirect to lastfm auth page with the proper url
  """
  def link(conn, _params) do
    redirect_uri =
      Routes.lastfm_auth_url(MusicSyncWeb.Endpoint, :authorize)
      |> URI.encode()

    url = "http://www.last.fm/api/auth?api_key=#{@client_id}&cb=#{redirect_uri}"

    redirect(conn, external: url)
  end

  @doc """
  Callback from authorizing with lastfm api.

  We are guaranteed to have a user logged in when executing on this.
  """
  def authorize(conn, params) do
    with {:ok, %{status: 200, body: %{"session" => %{"key" => session_key}}}} <-
           Lastfm.login(params["token"]),
         client <- Lastfm.authenticated_client(session_key),
         current_user <- conn.assigns[:current_user],
         {:ok, %{status: 200, body: lastfm_user_info}} <- Lastfm.get_user_info(client),
         {:ok, user} <-
           Accounts.update_user(current_user, %{
             lastfm_session_key: session_key,
             lastfm_username: lastfm_user_info["user"]["name"]
           }) do
      msg = "Successfully linked lastfm #{user.lastfm_username} with #{user.username}"
      Logger.debug(msg)

      conn
      |> put_flash(:info, msg)
      |> redirect(to: "/")
    else
      {:ok, %{status: status, body: %{"error" => _, "message" => err_msg}}} ->
        Logger.error("http #{status} lastfm error: #{err_msg}")

        conn
        |> put_flash(:error, "Error linking lastfm")
        |> redirect(to: "/")

      {:error, err} ->
        Logger.error("unable to login to lastfm due to #{inspect(err)}")

        conn
        |> put_flash(:error, "Error linking lastfm")
        |> redirect(to: "/")
    end
  end
end
