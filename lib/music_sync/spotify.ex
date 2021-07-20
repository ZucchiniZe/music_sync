defmodule Spotify do
  @moduledoc """
  Interfacing with the Spotify API

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  use Tesla
  require Logger
  alias MusicSync.Accounts.User

  ## login methods
  @spec login_client :: Tesla.Client.t()
  def login_client do
    config = Application.get_env(:music_sync, MusicSync.Spotify)

    middleware = [
      {Tesla.Middleware.BasicAuth,
       username: config[:client_id], password: config[:client_secret]},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  def get_token(client, params) do
    post(client, "https://accounts.spotify.com/api/token", params)
  end

  ## authenticated methods
  @doc """
  Generate a `Tesla` client with a users access token
  """
  def authenticated_client(%User{spotify_access_token: token}) do
    authenticated_client(token)
  end

  def authenticated_client(access_token) do
    middleware = [
      {Tesla.Middleware.Retry,
       [
         delay: 500,
         max_delay: 5000,
         should_retry: fn
           {:ok, %{status: status}} when status in [429] -> true
           _ -> false
         end
       ]},
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      Tesla.Middleware.JSON
      # Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
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
