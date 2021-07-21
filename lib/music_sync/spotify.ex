defmodule Spotify do
  @moduledoc """
  Interfacing with the Spotify API

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  use Tesla
  require Logger
  alias MusicSync.Accounts
  alias MusicSync.Accounts.User

  ## login methods
  @doc """
  Create a short lived tesla client and then request auth and refresh tokens
  from spotify.
  """
  def get_token(params) do
    config = Application.get_env(:music_sync, MusicSync.Spotify)

    middleware = [
      {Tesla.Middleware.BasicAuth,
       username: config[:client_id], password: config[:client_secret]},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Telemetry, metadata: %{client: "spotify.login"}}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Finch, name: MusicSync.Finch})
    post(client, "https://accounts.spotify.com/api/token", params)
  end

  ## authenticated methods
  @doc """
  Generate a `Tesla` client with a users access token. Also checks that the
  token is valid, if it is expired, refresh it automatically.
  """
  def authenticated_client(%User{spotify_access_token: old_token} = user) do
    if Accounts.spotify_token_expired?(user) do
      {:ok, %User{spotify_access_token: new_token}} = Accounts.refresh_spotify_token(user)
      authenticated_client(new_token)
    else
      authenticated_client(old_token)
    end
  end

  def authenticated_client(access_token) do
    middleware = [
      MusicSync.Middleware.Retry,
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Telemetry, metadata: %{client: "spotify.auth"}}
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MusicSync.Finch})
  end

  @doc """
  Gets the personal info for the authenticated user
  """
  def get_user_info(client) do
    get(client, "/me")
  end

  @doc """
  Get the saved tracks for the authenticated spotify user

  Automatically paginates
  """
  # TODO: verify this actually works
  def saved_tracks(client) do
    # TODO: error handling
    case get(client, "/me/tracks", query: [limit: 1]) do
      {:ok, %{status: 200, body: %{"total" => total_tracks}}} ->
        # generate an array of offset numbers and map over it with http requests
        0..total_tracks//50
        |> Enum.map(fn offset ->
          Task.async(fn ->
            # TODO: error handling
            Logger.info("hitting spotify with offset #{offset}")

            case get(client, "/me/tracks", query: [offset: offset, limit: 50]) do
              {:ok, %{status: 200, body: %{items: items}}} ->
                items

              {_status, resp} ->
                Logger.debug(resp |> Map.delete(:body))
            end
          end)
        end)
        |> Task.await_many()
        |> Enum.concat()

      {:ok, %{body: error}} ->
        IO.inspect(error)

      {:error, reason} ->
        IO.inspect(reason)
    end
  end
end
