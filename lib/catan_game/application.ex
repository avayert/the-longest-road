defmodule Catan.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Catan.Repo,
      # Start the Telemetry supervisor
      CatanWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Catan.PubSub},
      # Start the Endpoint (http/https)
      CatanWeb.Endpoint,
      # Start a worker by calling: Catan.Worker.start_link(arg)
      Catan.GameSupervisor,
      Catan.PlayerSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Catan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CatanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
