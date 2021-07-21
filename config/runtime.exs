import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :music_sync, MusicSyncWeb.Endpoint,
    server: true,
    url: [host: "#{app_name}.fly.dev", port: 443, scheme: "https"],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
      # IMPORTANT: support IPv6 addresses
      transport_options: [socket_opts: [:inet6]]
    ],
    secret_key_base: secret_key_base

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :music_sync, MusicSync.Repo,
    url: database_url,
    # IMPORTANT: Or it won't find the DB server
    socket_options: [:inet6],
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  config :music_sync, MusicSync.PromEx,
    disabled: false,
    manual_metrics_start_delay: :no_delay,
    drop_metrics_groups: [],
    grafana: [
      host: "https://zucchinize.grafana.net",
      auth_token: System.get_env("GRAFANA_TOKEN") || "",
      upload_dashboards_on_start: true,
      folder_name: "App",
      annotate_app_lifecycle: true
    ],
    metrics_server: [port: 4005]
end
