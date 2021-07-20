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
    |> unique_constraint([:username, :email])
  end
end
