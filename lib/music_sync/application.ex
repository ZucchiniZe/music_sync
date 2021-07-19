defmodule MusicSync.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      MusicSync.Repo,
      # Start the Telemetry supervisor
      MusicSyncWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: MusicSync.PubSub},
      # Start the Endpoint (http/https)
      MusicSyncWeb.Endpoint,
      # Start the Finch client (http client)
      {Finch, name: MusicSync.Finch}
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
