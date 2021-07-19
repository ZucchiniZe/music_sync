defmodule MusicSyncWeb.PageController do
  use MusicSyncWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
