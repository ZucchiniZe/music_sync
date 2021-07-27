defmodule MusicSync.ServiceTest do
  use ExUnit.Case, async: true

  describe "spotify" do
    alias Service.Spotify

    test "authenticated_client/1 returns an authenticated client for a user object"
    test "authenticated_client/1 returns an authenticated client for raw params"

    test "saved_tracks/1 correctly paginates through all pages on fresh user"
    test "saved_tracks/1 correctly paginates only through recent pages"
    test "saved_tracks/1 correctly paginates through all pages on old user"
  end

  describe "lastfm" do
    alias Service.Lastfm

    test "authenticated_client/1 returns an authenticated client for a user object"
    test "authenticated_client/1 returns an authenticated client for raw params"
  end
end
