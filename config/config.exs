# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :music_sync,
  ecto_repos: [MusicSync.Repo]

# Configures the endpoint
config :music_sync, MusicSyncWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "b6zKFbf4QzCjJ47MfCwfQDE3MjOAgzqLpGlSvCrRO8yw2+w+lKjBScb/uoUQBS6i",
  render_errors: [view: MusicSyncWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: MusicSync.PubSub,
  live_view: [signing_salt: "QxRBP9L9"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :music_sync, MusicSync.Spotify,
  client_id: "20cf26fd82a84e02a34e9cfa891d29d6",
  client_secret: "2a7f0ceb011d43a0bd249acbf0621991"

config :music_sync, MusicSync.Lastfm,
  client_id: "1588c9955843371816a1f2b2233a5cd9",
  client_secret: "ec15cb50fd817a062e7dfe10b1925f95"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
