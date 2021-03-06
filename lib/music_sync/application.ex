defmodule MusicSync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @cache_name Application.compile_env!(:music_sync, [MusicSync.Spotify, :cache])

  def start(_type, _args) do
    children = [
      # Start the prometheus reporter,
      MusicSync.PromEx,
      # Start the Telemetry supervisor
      MusicSyncWeb.Telemetry,
      # Start the Ecto repository
      MusicSync.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: MusicSync.PubSub},
      # Start the Endpoint (http/https)
      MusicSyncWeb.Endpoint,
      # Start the Finch client (http client)
      {Finch, name: MusicSync.Finch, pools: %{default: [max_idle_time: 120_000]}},
      # Start the spotify response cache
      {Cachex, name: @cache_name, stats: true},
      {Task.Supervisor, name: MusicSync.TaskSupervisor}
      # Start a worker by calling: MusicSync.Worker.start_link(arg)
      # {MusicSync.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MusicSync.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MusicSyncWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
