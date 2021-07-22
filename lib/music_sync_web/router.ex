defmodule MusicSyncWeb.Router do
  use MusicSyncWeb, :router

  import MusicSyncWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MusicSyncWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/logout", UserController, :logout
  end

  scope "/", MusicSyncWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/spotify/login", SpotifyAuthController, :login
    get "/spotify/authorize", SpotifyAuthController, :authorize
  end

  scope "/", MusicSyncWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/spotify/refresh", SpotifyAuthController, :refresh

    get "/lastfm/link", LastfmAuthController, :link
    get "/lastfm/authorize", LastfmAuthController, :authorize

    get "/profile", UserController, :show
    delete "/profile", UserController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", MusicSyncWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: MusicSyncWeb.Telemetry, ecto_repos: [MusicSync.Repo]
    end
  end
end
