defmodule MusicSync.AccountsTest do
  use MusicSync.DataCase

  alias MusicSync.Accounts

  describe "users" do
    alias MusicSync.Accounts.User

    @time ~N[2021-07-27 03:25:32]

    # lastfm session key is a md5 hash so 32 char long
    # spotify access token is 176 char long
    # spotify refresh token is 131 char long
    @valid_attrs %{
      email: "some email",
      name: "some name",
      username: "some username",
      lastfm_username: "some lastfm_username",
      lastfm_session_key: "ATEon82JKYhzgd2Ae58APq6RwxstlAfA",
      spotify_access_token:
        "j11RKKS-46jqe60iggOcVqhPD6BAlBfig-Zq2qq1KZhGtlOajBi58INVKIj-_cb9K6Vlg-bk32iCB3YSBSv6WC3MgZqrdCjb3NSIuCiAY7RzhP-6PVV4KEzDUA_lY_DBk547L4aF-5x1SB6chWNVFhVcCggSbF5VtFSZ4xIbN4_1cSge",
      spotify_refresh_token:
        "2gGg3QRgcrXOGW9unoLbSkCiwKeTiyaMLVsIYbUCgII_VA5Exri0r3KIAt5tE1ArctK9wTw-rH8Q--rEMBAG90cAr2C8HAAF3MCKjcAJ0IgrF-KrQGYiFLEg3d511gdzAwx",
      spotify_token_expiry: @time
    }
    @update_attrs %{
      email: "some updated email",
      name: "some updated name",
      username: "some updated username",
      lastfm_username: "some updated lastfm_username",
      lastfm_session_key: "d8e8fca2dc0f896fd7cb4cb0031ba249",
      spotify_access_token:
        "gFrlAwMfJTJrwxC_-P5NPSCtkI3CHwvX6rJYk0wGCrw_gLGcLnBZHdwCowGy0XrAK5BcLKCC0U-g1UcrXbxC_9NNwuwCJxIMJRuntiUrK5rrA8wrer5Mb80abcuUJLMl3P1EI8HLGYnQBogrrXkx0iUk85eUKU-lbLflrB59kGN39vXt",
      spotify_refresh_token:
        "jbl9_grIJxIrwFU8idOWTirAxNPHj3CryVPUf9wmCQ8kkQwTJxli_YIxOPLsKv8uBIkC8JtaDBwgAQ1FbknLDCrmBwgbQUN2scSJ_1CoiKIk-jx-YwOblFEIrPwTUy95K3a",
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
      assert user.lastfm_session_key == "ATEon82JKYhzgd2Ae58APq6RwxstlAfA"

      assert user.spotify_access_token ==
               "j11RKKS-46jqe60iggOcVqhPD6BAlBfig-Zq2qq1KZhGtlOajBi58INVKIj-_cb9K6Vlg-bk32iCB3YSBSv6WC3MgZqrdCjb3NSIuCiAY7RzhP-6PVV4KEzDUA_lY_DBk547L4aF-5x1SB6chWNVFhVcCggSbF5VtFSZ4xIbN4_1cSge"

      assert user.spotify_refresh_token ==
               "2gGg3QRgcrXOGW9unoLbSkCiwKeTiyaMLVsIYbUCgII_VA5Exri0r3KIAt5tE1ArctK9wTw-rH8Q--rEMBAG90cAr2C8HAAF3MCKjcAJ0IgrF-KrQGYiFLEg3d511gdzAwx"

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
      assert user.lastfm_session_key == "d8e8fca2dc0f896fd7cb4cb0031ba249"

      assert user.spotify_access_token ==
               "gFrlAwMfJTJrwxC_-P5NPSCtkI3CHwvX6rJYk0wGCrw_gLGcLnBZHdwCowGy0XrAK5BcLKCC0U-g1UcrXbxC_9NNwuwCJxIMJRuntiUrK5rrA8wrer5Mb80abcuUJLMl3P1EI8HLGYnQBogrrXkx0iUk85eUKU-lbLflrB59kGN39vXt"

      assert user.spotify_refresh_token ==
               "jbl9_grIJxIrwFU8idOWTirAxNPHj3CryVPUf9wmCQ8kkQwTJxli_YIxOPLsKv8uBIkC8JtaDBwgAQ1FbknLDCrmBwgbQUN2scSJ_1CoiKIk-jx-YwOblFEIrPwTUy95K3a"

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
