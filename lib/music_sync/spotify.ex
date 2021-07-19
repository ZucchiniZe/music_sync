defmodule Spotify do
  use Tesla

  ## login methods
  def login_client do
    middleware = [
      Tesla.Middleware.DecodeJson,
      Tesla.Middleware.EncodeFormUrlencoded
    ]

    Tesla.client(middleware)
  end

  def get_token(client, params) do
    post(client, "/token", params)
  end

  ## authenticated methods
  def authenticated_client(access_token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "https://api.spotify.com/v1"},
      {Tesla.Middleware.BearerAuth, token: access_token},
      Tesla.Middleware.JSON
    ]

    Tesla.client(middleware)
  end

  @doc """
  Get the saved tracks for the current spotify user

  Automatically paginates
  """
  def saved_tracks(client) do
    get(client, "/me/tracks")
  end
end
