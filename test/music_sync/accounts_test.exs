defmodule MusicSync.AccountsTest do
  use MusicSync.DataCase

  alias MusicSync.Accounts

  describe "users" do
    alias MusicSync.Accounts.User

    @valid_attrs %{email: "some email", lastfm_auth_token: "some lastfm_auth_token", lastfm_session_key: "some lastfm_session_key", spotify_access_token: "some spotify_access_token", spotify_id: "some spotify_id", spotify_refresh_token: "some spotify_refresh_token", username: "some username"}
    @update_attrs %{email: "some updated email", lastfm_auth_token: "some updated lastfm_auth_token", lastfm_session_key: "some updated lastfm_session_key", spotify_access_token: "some updated spotify_access_token", spotify_id: "some updated spotify_id", spotify_refresh_token: "some updated spotify_refresh_token", username: "some updated username"}
    @invalid_attrs %{email: nil, lastfm_auth_token: nil, lastfm_session_key: nil, spotify_access_token: nil, spotify_id: nil, spotify_refresh_token: nil, username: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.lastfm_auth_token == "some lastfm_auth_token"
      assert user.lastfm_session_key == "some lastfm_session_key"
      assert user.spotify_access_token == "some spotify_access_token"
      assert user.spotify_id == "some spotify_id"
      assert user.spotify_refresh_token == "some spotify_refresh_token"
      assert user.username == "some username"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.lastfm_auth_token == "some updated lastfm_auth_token"
      assert user.lastfm_session_key == "some updated lastfm_session_key"
      assert user.spotify_access_token == "some updated spotify_access_token"
      assert user.spotify_id == "some updated spotify_id"
      assert user.spotify_refresh_token == "some updated spotify_refresh_token"
      assert user.username == "some updated username"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
