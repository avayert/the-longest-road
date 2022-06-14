defmodule Catan.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Catan.Repo,
      CatanWeb.Telemetry,
      {Phoenix.PubSub, name: Catan.PubSub},
      CatanWeb.Endpoint,
      Catan.GameCoordinator,
      Catan.EngineSupervisor
    ]

    opts = [strategy: :one_for_one, name: Catan.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CatanWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
