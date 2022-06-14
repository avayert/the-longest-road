defmodule Catan.EngineSupervisor do
  use Supervisor

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args, name: __MODULE__)
  end

  @impl true
  def init(_init_args) do
    children = [
      # Registry for the game instance supervisors
      {Registry, keys: :unique, name: GameRegistry},

      # game supervisor that holds the game instance supervisors
      {DynamicSupervisor, strategy: :one_for_one, name: GameManager},

      # Registry and supervisor for player instances
      {Registry, keys: :unique, name: PlayerRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: PlayerManager},

      # Registry for map instances
      {Registry, keys: :unique, name: MapRegistry},

      # Registry and supervisor for lobby instances
      {Registry, keys: :unique, name: LobbyRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: LobbyManager}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
