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
      field :current_directive, [], default: []
      field :mode_states, %{module() => %{atom() => term()}}, default: %{}
      field :mode_tree, [], default: []
    end

    use Accessible

    def new(state), do: struct(__MODULE__, state)
  end

  @type game_state :: GameState.t()

  def start_link(opts) do
    {name, state} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def init(lobby: nil) do
    {:stop, :no_lobby}
  end

  @impl true
  def init(state) do
    state =
      state
      |> Enum.into(%{})
      |> GameState.new()
      |> build_mode_list()

    mode_inits =
      map_modes(state, fn m ->
        m.init(state)
      end)

    mode_states =
      for {:ok, modestate, _directive} <- mode_inits, reduce: %{} do
        acc -> Map.put(acc, modestate.mode, modestate)
      end

    {_, _, [directive]} = Enum.find(mode_inits, fn {:ok, _state, dir} -> dir end)

    state =
      state
      |> Map.put(:mode_states, mode_states)
      |> Map.update!(:current_directive, fn cur -> [directive | cur] end)

    :ok = CatanWeb.Endpoint.subscribe("game:#{state.lobby.id}")
    {:ok, state, {:continue, :init}}
  end

  @spec build_mode_list(game_state()) :: game_state()
  def build_mode_list(state) do
    state
    |> Map.update!(:mode_tree, fn _ ->
      state.lobby.scenarios ++ nil2l(state.lobby.expansion) ++ [state.lobby.game_mode]
    end)
  end

  defp nil2l(exp) when is_nil(exp), do: []
  defp nil2l(exp), do: [exp]

  @spec map_modes(state :: game_state(), func :: (module() -> any())) :: any()
  defp map_modes(state, func) do
    for mode <- state.mode_tree do
      func.(mode)
    end
  end

  ## Actual functions

  @spec resolve_directive(state :: game_state(), Helpers.directive()) :: any
  def resolve_directive(state, directive) do
    Enum.reduce_while(state.mode_tree, nil, fn mod, _acc ->
      case query_game_mode(state, mod, directive) do
        {:ok, next_directive, state} -> {:halt, {next_directive, state}}
        :not_implemented -> {:cont, nil}
      end
    end)
  end

  def query_game_mode(state, mode, directive) do
    apply(mode, :handle_directive, [directive, state])
  end

  @impl true
  def handle_continue(op, state) do
    Logger.info("Game got continue op: #{inspect(op)}")
    Logger.info("Resolving #{inspect(state.current_directive)}")

    {thing, state} =
      try do
        {_thing, _state} = resolve_directive(state, state.current_directive)
      rescue
        FunctionClauseError ->
          Logger.alert("No function clause found for #{inspect(state.current_directive)}")
          {:err, state}

        e ->
          Logger.error(Exception.format(:error, e, __STACKTRACE__))
          {:err, state}
      end

    Logger.info("Resolved, continue done")
    Logger.info("game.ex:#{__ENV__.line}: got: #{inspect(thing)}")

    # TODO: handle action vs phase continuance

    {:noreply, state}
  end
end
