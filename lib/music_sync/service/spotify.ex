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

  @adapter Application.compile_env(
             :tesla,
             :adapter,
             {Tesla.Adapter.Finch, name: MusicSync.Finch}
           )

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

    client = Tesla.client(middleware, @adapter)
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

    Tesla.client(middleware, @adapter)
  end

  @doc """
  Gets the personal info for the authenticated user.
  """
  def get_user_info(client) do
    get(client, "/me")
  end

  @doc """
  Get all saved tracks for the authenticated spotify user given the most recent
  track time in the database. Prevents hitting the api unnecessarily.
  Automatically paginates through all the pages.

  ## Examples

      iex> user = Accounts.get_user_by_id!(1)
      %User{}

      iex> saved_tracks(client, user.most_recent_track)
      [%{}, %{}, %{}, ...]

  """
  # TODO: implement some telemetry for all this
  def saved_tracks(client, latest_track_date) do
    # get the total number of tracks we need to grab and the most recent date
    case get(client, "/me/tracks", query: [limit: 1]) do
      {:ok, %{status: 200, body: %{"total" => total_tracks} = body}} ->
        most_recent_track =
          body["items"]
          |> List.first()
          |> Map.get("added_at")
          |> NaiveDateTime.from_iso8601!()

        # if the most recent track added to the library is more recent than the
        # saved track in the database, then get the saved tracks
        if NaiveDateTime.compare(most_recent_track, latest_track_date) == :gt do
          {:ok, get_saved_tracks(client, total_tracks)}
        else
          {:error, "no recent tracks"}
        end

      {:ok, %{body: error}} ->
        error |> inspect |> Logger.error()
        {:error, error}

      {:error, error} ->
        error |> inspect |> Logger.error()
        {:error, error}
    end
  end

  defp get_saved_tracks(client, total_tracks) do
    # generate a range of offset numbers and map over it with http requests
    # then run a `Task` for each of them to run in parallel.
    0..total_tracks//50
    |> Enum.map(fn offset ->
      # TODO: put these under a `DynamicSupervisor` so we can monitor
      # TODO: do some error handling, maybe raise an error
      Task.async(fn -> paginate_saved_tracks(client, offset) end)
    end)
    # account for the rate limiting delays
    |> Task.await_many(:infinity)
    |> Enum.concat()
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
