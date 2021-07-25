defmodule Service.Spotify do
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
    if Accounts.User.spotify_token_expired?(user) do
      {:ok, %User{spotify_access_token: new_token}} = Accounts.refresh_spotify_token(user)
      authenticated_client(new_token)
    else
      authenticated_client(old_token)
    end
  end

  def authenticated_client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Telemetry, metadata: %{client: "spotify.auth"}}
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MusicSync.Finch})
  end

  @doc """
  Gets the personal info for the authenticated user.
  """
  def get_user_info(client) do
    get(client, "/me")
  end

  @doc """
  Get all saved tracks for the authenticated spotify user.

  Automatically paginates
  """
  # TODO: implement some telemetry for all this
  def saved_tracks(client) do
    # get the total number of tracks we need to grab and then build a list to
    # paginate by
    case get(client, "/me/tracks", query: [limit: 1]) do
      {:ok, %{status: 200, body: %{"total" => total_tracks}}} ->
        # generate an array of offset numbers and map over it with http requests
        # then run a `Task` for each of them to run in parallel.
        0..total_tracks//50
        |> Enum.map(fn offset ->
          Task.async(fn -> paginate_saved_tracks(client, offset) end)
        end)
        # account for the rate limiting delays
        |> Task.await_many(:infinity)
        |> Enum.concat()

      {:ok, %{body: error}} ->
        error |> inspect |> Logger.error()

      {:error, error} ->
        error |> inspect |> Logger.error()
    end
  end

  # some recursive shenanigans that retry a request when we get rate limited
  defp paginate_saved_tracks(client, offset, retries \\ 0) when retries <= 10 do
    # we _really_ don't need to log these requests
    client = %Tesla.Client{client | pre: List.keydelete(client.pre, Tesla.Middleware.Logger, 0)}

    case get(client, "/me/tracks", query: [offset: offset, limit: 50]) do
      {:ok, %{status: 200, body: %{"items" => items}}} ->
        items

      # we are rate limited if we get a 429 status code and then have to peek into
      # the Retry-After header to wait than many seconds
      {:ok, %{status: 429} = resp} ->
        {_, delay} = List.keyfind(resp.headers, "retry-after", 0, "1")
        delay = String.to_integer(delay)
        :timer.sleep(delay * 1000)
        paginate_saved_tracks(client, offset, retries + 1)

      {:error, resp} ->
        Logger.error("hit an error with offset #{offset}")
        Logger.debug(inspect(resp))

      other ->
        Logger.error("misc error")
        Logger.debug(inspect(other))
    end
  end
end
