defmodule Lastfm do
  @moduledoc """
  Interfacing with the last.fm api

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  use Tesla
  require Logger
  alias MusicSync.Accounts.User

  @client_id Application.get_env(:music_sync, MusicSync.Lastfm)[:client_id]

  def login(token) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "http://ws.audioscrobbler.com/2.0"},
      {Tesla.Middleware.Query, [api_key: @client_id]},
      Tesla.Middleware.DecodeJson,
      Lastfm.APISigMiddleware,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Telemetry, metadata: %{client: "lastfm.login"}}
    ]

    client = Tesla.client(middleware, {Tesla.Adapter.Finch, name: MusicSync.Finch})

    get(client, "", query: [token: token, method: "auth.getSession"])
  end

  def authenticated_client(%User{lastfm_session_key: token}) do
    authenticated_client(token)
  end

  def authenticated_client(session_key) do
    middleware = [
      {Tesla.Middleware.BaseUrl, "http://ws.audioscrobbler.com/2.0"},
      {Tesla.Middleware.Query, [api_key: @client_id, sk: session_key]},
      Tesla.Middleware.DecodeJson,
      Lastfm.APISigMiddleware,
      Tesla.Middleware.Logger,
      {Tesla.Middleware.Telemetry, metadata: %{client: "lastfm.auth"}}
    ]

    Tesla.client(middleware, {Tesla.Adapter.Finch, name: MusicSync.Finch})
  end

  def get_user_info(client) do
    get(client, "", query: [method: "user.getInfo"])
  end
end