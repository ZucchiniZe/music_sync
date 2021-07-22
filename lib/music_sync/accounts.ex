defmodule MusicSync.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias MusicSync.Repo

  alias MusicSync.Accounts.User

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.
  """
  def get_user_by_id!(id), do: Repo.get!(User, id)

  @doc """
  Gets a single user by their refresh token
  """
  def get_user_by_refresh_token!(token), do: Repo.get_by!(User, spotify_refresh_token: token)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def create_or_update_user_from_spotify_info(%{"error" => %{"message" => reason}}, _token_info) do
    # if the api errors for some reason, exit early with an error
    {:error, reason}
  end

  @doc """
  Creates or updates a user from the raw info spotify returns from `/v1/me` and
  their tokens

  returns `{:ok, user}` or `{:error, reason}`
  """
  def create_or_update_user_from_spotify_info(user_info, token_info) do
    user_attrs = %{
      email: user_info |> Map.get("email", ""),
      name: user_info |> Map.get("display_name", ""),
      username: user_info |> Map.get("id", "")
    }

    token_attrs = %{
      spotify_access_token: token_info["access_token"],
      spotify_refresh_token: token_info["refresh_token"],
      spotify_token_expiry: NaiveDateTime.add(NaiveDateTime.utc_now(), token_info["expires_in"])
    }

    timestamped_attrs =
      Map.put(
        token_attrs,
        :updated_at,
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      )
      |> Enum.into([])

    attrs = Map.merge(user_attrs, token_attrs)

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(
      on_conflict: [set: timestamped_attrs],
      conflict_target: [:username, :email],
      returning: true
    )
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Make a request to spotify to refresh the access token (they are short lived)
  and update the user in the database with new tokens
  """
  def refresh_spotify_token(%User{} = user) do
    post_params = %{grant_type: "refresh_token", refresh_token: user.spotify_refresh_token}

    with {:ok, %{status: 200, body: token_info}} <-
           Spotify.get_token(post_params),
         {:ok, user} <-
           update_user(user, %{
             spotify_access_token: token_info["access_token"],
             spotify_token_expiry:
               NaiveDateTime.add(NaiveDateTime.utc_now(), token_info["expires_in"])
           }) do
      {:ok, user}
    end
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end
end
