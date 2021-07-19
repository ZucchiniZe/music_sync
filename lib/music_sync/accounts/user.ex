defmodule MusicSync.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :username, :string
    field :spotify_id, :string
    field :spotify_access_token, :string
    field :spotify_refresh_token, :string
    field :lastfm_auth_token, :string
    field :lastfm_session_key, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :username,
      :spotify_id,
      :spotify_access_token,
      :spotify_refresh_token,
      :lastfm_auth_token,
      :lastfm_session_key
    ])
    |> validate_required([:email, :spotify_id, :username])
  end
end
