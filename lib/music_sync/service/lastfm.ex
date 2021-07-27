defmodule Service.Lastfm do
  @moduledoc """
  Interfacing with the last.fm api

  Separated into two sections, each with their own middleware. First section for
  login methods and the second for methods requiring authentication.
  """
  use Tesla
  require Logger
  alias MusicSync.Accounts.User

  @client_id Application.compile_env!(:music_sync, [MusicSync.Lastfm, :client_id])
  @adapter Application.compile_env(
             :tesla,
             :adapter,
             {Tesla.Adapter.Finch, name: MusicSync.Finch}
           )
  @middleware [
    {Tesla.Middleware.BaseUrl, "http://ws.audioscrobbler.com/2.0"},
    {Tesla.Middleware.Query, [api_key: @client_id]},
    Tesla.Middleware.DecodeJson,
    MusicSync.Middleware.APISignature,
    Tesla.Middleware.Logger
  ]

  def login(token) do
    middleware =
      @middleware ++ [{Tesla.Middleware.Telemetry, metadata: %{client: "lastfm.login"}}]

    client = Tesla.client(middleware, @adapter)

    get(client, "", query: [token: token, method: "auth.getSession"])
  end

  def authenticated_client(%User{lastfm_session_key: token}) do
    authenticated_client(token)
  end

  def authenticated_client(session_key) do
    middleware =
      List.keyreplace(
        @middleware,
        Tesla.Middleware.Query,
        0,
        {Tesla.Middleware.Query, [api_key: @client_id, sk: session_key]}
      ) ++ [{Tesla.Middleware.Telemetry, metadata: %{client: "lastfm.auth"}}]

    Tesla.client(middleware, @adapter)
  end

  @doc """
  Get the user's info from the lastfm api
  """
  def get_user_info(client) do
    get(client, "", query: [method: "user.getInfo"])
  end

  @doc """
  Mark a track as loved on lastfm

  ## Examples

      iex> love_track(client, %{artist: "Bon Iver", track: "Hey Ma"})
      {:ok, Tesla.Env.t()}
  """
  def love_track(client, %{artist: artist, track: track}) do
    post(client, "", "", query: [method: "track.love", artist: artist, track: track])
  end

  @doc """
  Unmark a track as loved on lastfm

  ## Examples

      iex> unlove_track(client, %{artist: "Bon Iver", track: "Hey Ma"})
      {:ok, Tesla.Env.t()}
  """
  def unlove_track(client, %{artist: artist, track: track}) do
    post(client, "", "", query: [method: "track.unlove", artist: artist, track: track])
  end
end
