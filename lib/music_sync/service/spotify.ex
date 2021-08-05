defmodule Service.Spotify do
  @moduledoc """
  Interfacing with the Spotify API

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  use Tesla
  require Logger
  alias MusicSync.Telemetry
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

  ## Examples

      iex> user = Accounts.get_user_by_id!(1)
      %User{}

      iex> Spotify.authenticated_client(user)
      %Tesla.Client{}

  """
  def authenticated_client(%User{spotify_access_token: old_token, id: username} = user) do
    if Accounts.User.spotify_token_expired?(user) do
      {:ok, %User{spotify_access_token: new_token}} = Accounts.refresh_spotify_token(user)
      authenticated_client(new_token, username)
    else
      authenticated_client(old_token, username)
    end
  end

  def authenticated_client(access_token, username \\ nil) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      {Tesla.Middleware.Opts, [username: username, service: :spotify]},
      {MusicSync.Middleware.Cache, :username},
      {MusicSync.Middleware.RateLimit, [limit: 10, per: 2_500]},
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
  track time in the database. Automatically paginates through all the pages.

  ## Examples

      iex> user = Accounts.get_user_by_id!(1)
      %User{}

      iex> saved_tracks(client)
      {:ok, [%{}, %{}, %{}, ...]}

  """
  def saved_tracks(client) do
    # get the total number of tracks we need to grab and the most recent date
    case get(client, "/me/tracks", query: [limit: 1]) do
      {:ok, %{status: 200, opts: opts, body: %{"total" => total_tracks}}} ->
        username = opts[:username]

        tracks =
          :telemetry.span(
            [:music_sync, :spotify_saved_tracks],
            %{
              total_tracks: total_tracks,
              pages: Float.ceil(total_tracks / 50) |> trunc,
              user: username
            },
            fn ->
              tracks = paginate_saved_tracks(client, total_tracks, username)
              {tracks, %{tracks_in_library: length(tracks)}}
            end
          )

        {:ok, tracks}

      {:ok, %{body: error}} ->
        error |> inspect |> Logger.error()
        {:error, error}

      {:error, error} ->
        error |> inspect |> Logger.error()
        {:error, error}
    end
  end

  # generate a range of offset numbers and map over it with http requests then
  # run an async_stream/5 over it so we get auto parrallelization.
  defp paginate_saved_tracks(client, total_tracks, username) do
    Task.Supervisor.async_stream(
      MusicSync.TaskSupervisor,
      0..total_tracks//50,
      &saved_tracks_page(client, &1, username),
      timeout: :timer.seconds(30)
    )
    |> Stream.map(fn {:ok, val} -> val end)
    |> Stream.concat()
    |> Enum.to_list()
  end

  # some recursive shenanigans that retry a request when we get rate limited
  defp saved_tracks_page(client, offset, username, retries \\ 0) when retries <= 10 do
    # we _really_ don't need to log these requests
    client = %Tesla.Client{client | pre: List.keydelete(client.pre, Tesla.Middleware.Logger, 0)}
    metadata = %{user: username, page: (offset / 50) |> trunc, retry: retries}

    start_time = Telemetry.start(:spotify_saved_tracks_page, metadata)

    case get(client, "/me/tracks", query: [offset: offset, limit: 50]) do
      {:ok, %{status: 200, body: %{"items" => items}}} ->
        Telemetry.stop(:spotify_saved_tracks_page, start_time, metadata)

        items

      # we are rate limited if we get a 429 status code and then have to peek into
      # the Retry-After header to wait than many seconds + 1
      {:ok, %{status: 429} = resp} ->
        delay =
          resp
          |> Tesla.get_header("retry-after")
          |> String.to_integer()
          |> Kernel.+(1)
          |> :timer.seconds()

        duration = System.monotonic_time() - start_time

        Telemetry.event(
          [:spotify_saved_tracks_page, :rate_limit],
          %{
            retry_after: delay - :timer.seconds(1),
            delay: delay,
            duration: duration
          },
          metadata
        )

        Logger.debug("retry ##{retries}: rate limited on #{offset} waiting #{delay}ms")
        :timer.sleep(delay)
        saved_tracks_page(client, offset, username, retries + 1)

      {:error, resp} ->
        Logger.error("hit an error with offset #{offset}")
        Logger.debug(inspect(resp))

      other ->
        Logger.error("misc error")
        Logger.debug(inspect(other))
    end
  end
end
