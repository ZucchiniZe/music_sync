defmodule MusicSync.AccountsTest do
  use MusicSync.DataCase

  alias MusicSync.Accounts

  describe "users" do
    alias MusicSync.Accounts.User

    @time ~N[2021-07-27 03:25:32]

    @valid_attrs %{
      email: "some email",
      name: "some name",
      username: "some username",
      lastfm_username: "some lastfm_username",
      lastfm_session_key: "some lastfm_session_key",
      spotify_access_token: "some spotify_access_token",
      spotify_refresh_token: "some spotify_refresh_token",
      spotify_token_expiry: @time
    }
    @update_attrs %{
      email: "some updated email",
      name: "some updated name",
      username: "some updated username",
      lastfm_username: "some updated lastfm_username",
      lastfm_session_key: "some updated lastfm_session_key",
      spotify_access_token: "some updated spotify_access_token",
      spotify_refresh_token: "some updated spotify_refresh_token",
      spotify_token_expiry: NaiveDateTime.add(@time, 1 * 60 * 60)
    }
    @invalid_attrs %{
      email: nil,
      name: nil,
      username: nil,
      lastfm_username: nil,
      lastfm_session_key: nil,
      spotify_access_token: nil,
      spotify_refresh_token: nil,
      spotify_token_expiry: nil
    }

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

    test "get_user_by_id!/1 returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user_by_id!(user.id) == user
    end

    test "get_user_by_refresh_token/1 returns the user with a given refresh token" do
      user = user_fixture()
      assert Accounts.get_user_by_refresh_token!(user.spotify_refresh_token) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.create_user(@valid_attrs)
      assert user.email == "some email"
      assert user.name == "some name"
      assert user.username == "some username"
      assert user.lastfm_username == "some lastfm_username"
      assert user.lastfm_session_key == "some lastfm_session_key"
      assert user.spotify_access_token == "some spotify_access_token"
      assert user.spotify_refresh_token == "some spotify_refresh_token"
      assert user.spotify_token_expiry == @time
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
      assert user.email == "some updated email"
      assert user.name == "some updated name"
      assert user.username == "some updated username"
      assert user.lastfm_username == "some updated lastfm_username"
      assert user.lastfm_session_key == "some updated lastfm_session_key"
      assert user.spotify_access_token == "some updated spotify_access_token"
      assert user.spotify_refresh_token == "some updated spotify_refresh_token"
      assert user.spotify_token_expiry == NaiveDateTime.add(@time, 1 * 60 * 60)
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
      assert user == Accounts.get_user_by_id!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Accounts.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user_by_id!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end
  end
end
