defmodule Catan.Game do
  @moduledoc """
  TODO
  """

  use GenServer, restart: :transient
  require Logger

  defmodule GameState do
    use TypedStruct

    typedstruct do
      field :lobby, Catan.Lobby.t(), enforce: true
      field :state_step, [], default: []
      field :mode_state, %{module() => %{atom() => term()}}, default: %{}
      field :mode_tree, [], default: []
    end

    use Accessible

    def new(state), do: struct(__MODULE__, state)
  end

  def start_link(opts) do
    {name, state} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def init(state) do
    state =
      state
      |> Enum.into(%{})
      |> GameState.new()
      |> assemble_state()

    :ok = CatanWeb.Endpoint.subscribe("game:#{state.lobby.id}")
    {:ok, state, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, state) do
    # get initial state from gamemodes
    {:noreply, state}
  end

  @impl true
  def handle_continue(op, state) do
    Logger.info("Game got continue op #{op}")
    {:noreply, state}
  end

  defp assemble_state(state) do
    state
    |> Map.update!(:mode_tree, fn _ ->
      state.lobby.scenarios ++ state.lobby.expansion ++ state.mode_tree
    end)
  end
end
