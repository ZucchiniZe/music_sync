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

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
