defmodule MusicSyncWeb.UserController do
  use MusicSyncWeb, :controller
  alias MusicSync.Accounts
  alias MusicSyncWeb.UserAuth

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully!")
    |> UserAuth.log_out_user()
  end

  def show(conn, _params) do
    render(conn, "show.html")
  end

  def delete(conn, _params) do
    current_user = conn.assigns[:current_user]

    case Accounts.delete_user(current_user) do
      {:ok, _} ->
        text(conn, "deleted")

      {:error, reason} ->
        text(conn, "error  #{inspect(reason)}")
    end
  end
end
