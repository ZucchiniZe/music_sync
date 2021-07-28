defmodule MusicSync.PromEx do
  @moduledoc false
  use PromEx, otp_app: :music_sync

  alias PromEx.Plugins

  @impl true
  def plugins do
    [
      # PromEx built in plugins
      Plugins.Application,
      Plugins.Beam,
      {Plugins.Phoenix, router: MusicSyncWeb.Router},
      Plugins.Ecto
      # Plugins.Oban,
      # Plugins.PhoenixLiveView

      # Add your own PromEx metrics plugins
      # MusicSync.Users.PromExPlugin
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: 18
    ]
  end

  @impl true
  def dashboards do
    [
      # PromEx built in Grafana dashboards
      {:prom_ex, "application.json"},
      {:prom_ex, "beam.json"},
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"}
      # {:prom_ex, "oban.json"},
      # {:prom_ex, "phoenix_live_view.json"}

      # Add your dashboard definitions here with the format: {:otp_app, "path_in_priv"}
      # {:music_sync, "/grafana_dashboards/user_metrics.json"}
    ]
  end
end
