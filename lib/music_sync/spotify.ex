defmodule Spotify do
  @moduledoc """
  Interfacing with the Spotify API

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  @type access_token() :: String.t()
  use Tesla
  require Logger

  ## login methods
  @spec login_client :: Tesla.Client.t()
  def login_client do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://accounts.spotify.com/api"},
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.Logger
    ]

    Tesla.client(middleware)
  end

  def get_token(client, params) do
    post(client, "/token", params)
  end

  ## authenticated methods
  @doc """
  Generate a `Tesla` client with a users access token
  """
  @spec authenticated_client(access_token()) :: Tesla.Client.t()
  def authenticated_client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      Tesla.Middleware.JSON,
      Tesla.Middleware.Logger
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
  def saved_tracks(client) do
    # TODO: error handling
    case get(client, "/me/tracks", query: [limit: 1]) do
      {:ok, %{body: %{"total" => total_tracks}}} ->
        # generate an array of offset numbers and map over it with http requests
        0..total_tracks//50
        |> Enum.map(fn offset ->
          Task.async(fn ->
            # TODO: error handling
            Logger.info("hitting spotify with offset #{offset}")
            %{items: items} = get(client, "/me/tracks", query: [offset: offset, limit: 50])
            items
          end)
        end)
        |> Task.await_many()
        |> Enum.concat()

      {:error, reason} ->
        IO.inspect(reason)
    end
  end
end
