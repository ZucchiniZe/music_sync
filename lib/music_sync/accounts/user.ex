defmodule MusicSync.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :name, :string
    field :username, :string
    field :lastfm_username, :string
    field :spotify_access_token, :string
    field :spotify_refresh_token, :string
    field :spotify_token_expiry, :naive_datetime
    field :lastfm_session_key, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :name,
      :username,
      :lastfm_username,
      :spotify_access_token,
      :spotify_refresh_token,
      :spotify_token_expiry,
      :lastfm_session_key
    ])
    |> validate_required([:email, :name, :username])
    |> validate_length(:lastfm_session_key, is: 32)
    |> validate_length(:spotify_access_token, is: 176)
    |> validate_format(:spotify_access_token, ~r/[A-Za-z-_0-9]\w+/)
    |> validate_length(:spotify_refresh_token, is: 131)
    |> validate_format(:spotify_refresh_token, ~r/[A-Za-z-_0-9]\w+/)
    |> unique_constraint([:username, :email])
  end

  def spotify_token_expired?(%__MODULE__{spotify_token_expiry: expiry}) do
    case NaiveDateTime.compare(NaiveDateTime.utc_now(), expiry) do
      :gt -> true
      _ -> false
    end
  end
end
