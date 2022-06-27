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
      field :game_directives, [], default: []
      field :mode_states, %{module() => %{atom() => term()}}, default: %{}
      field :mode_tree, [], default: []
    end

    use Accessible

    def new(state), do: struct(__MODULE__, state)
  end

  @type game_state :: GameState.t()
  @type tick_result ::
          {:ok, Helpers.directives(), game_state()}
          | {:err, atom(), game_state()}

  def start_link(opts) do
    {name, state} = Keyword.pop(opts, :name)
    GenServer.start_link(__MODULE__, state, name: name)
  end

  @impl true
  def init(lobby: nil) do
    {:stop, :no_lobby}
  end

  @impl true
  def init(opts) do
    Logger.info("Starting game: #{Keyword.get(opts, :lobby).id}")

    state =
      opts
      |> Enum.into(%{})
      |> GameState.new()
      |> build_mode_list()

    mode_inits =
      map_modes(state, fn m ->
        m.init(state)
      end)

    mode_states =
      for {:ok, _directive, modestate} <- mode_inits, reduce: %{} do
        acc -> Map.put(acc, modestate.mode, modestate)
      end

    {_, [directive], _} = Enum.find(mode_inits, fn {:ok, dir, _state} -> dir end)

    state =
      state
      |> Map.put(:mode_states, mode_states)
      |> Map.update!(:game_directives, fn cur -> [directive | cur] end)

    :ok = CatanWeb.Endpoint.subscribe("game:#{state.lobby.id}")
    {:ok, state, {:continue, :init}}
  end

  @spec build_mode_list(state :: game_state()) :: game_state()
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

  defp push_directive(directive, state) do
    Map.update!(state, :game_directives, fn cur -> [directive | cur] end)
  end

  defp put_directives(directives, state) do
    Map.update!(state, :game_directives, fn _ -> directives end)
  end

  # defp pop_directive(state) do
  #   case state.game_directives do
  #     [] -> state
  #     _ -> Map.update!(state, :game_directives, fn cur -> tl(cur) end)
  #   end
  # end

  ## Actual functions

  @spec tick_game(state :: game_state()) :: tick_result()
  def tick_game(state) do
    Logger.info("Ticking game state")
    Logger.info("Resolving #{inspect(state.game_directives)}")

    try do
      {new_directives, new_state} = resolve_directives(state, state.game_directives)

      Logger.info("Resolved, game tick done")
      Logger.info("Got new directives: #{inspect(new_directives)}")

      new_state = put_directives(new_directives, new_state)

      {:ok, new_directives, new_state}
    rescue
      FunctionClauseError ->
        Logger.warning("No function clause found for #{inspect(state.game_directives)}")
        {:err, :no_clause, state}

      e ->
        Logger.error("Unknown error " <> Exception.format(:error, e, __STACKTRACE__))
        {:err, e, state}
    end
  end

  @spec resolve_directives(
          state :: game_state(),
          directives :: Helpers.directives()
        ) :: any()
  def resolve_directives(state, directives) do
    Enum.reduce_while(state.mode_tree, nil, fn mod, _acc ->
      case mod.dispatch(directives, state) do
        {:ok, next_directive, state} ->
          {:halt, {next_directive, state}}

        :not_implemented ->
          {:cont, nil}
      end
    end)
  end

  # @impl true
  # def handle_continue(:action, state) do
  #   Logger.info("Doing continue for :action")
  #   {:noreply, state}
  # end

  # @impl true
  # def handle_continue(:phase, state) do
  #   Logger.info("Doing continue for :phase")
  #   {:noreply, state}
  # end

  @impl true
  def handle_continue(op, state) do
    Logger.info("Game got continue op: #{inspect(op)}")
    # Logger.info("Game got continue for :init")

    state =
      case tick_game(state) do
        {:ok, _directives, state} ->
          state

        {:err, error, state} ->
          Logger.error("Tick returned error: #{inspect(error)}")
          state |> push_directive(phase: :game_error)
          # TODO: maybe change this to [error: :(old directive)]?
      end

    case state.game_directives do
      [{:action, _} | _] ->
        {:noreply, state, {:continue, :action}}

      [{:phase, _} | _] = cur_dirs ->
        Logger.info("End of the line for #{inspect(cur_dirs)}")
        {:noreply, state}

      :err ->
        Logger.error(
          "Bad(?) directive :err returned from:\n" <>
            (Process.info(self(), :current_stacktrace)
             |> elem(1)
             |> Enum.drop(1)
             |> Exception.format_stacktrace())
        )

      other ->
        Logger.warning("unknown new directive: #{inspect(other)}")
        {:noreply, state}
    end
  end

  # @impl true
  # def handle_continue(op, state) do
  #   Logger.info("Game got continue op: #{inspect(op)}")
  #   {:noreply, state}
  # end

  @impl true
  def handle_info({:player_input, player, event}, socket) do
    Logger.info("Got player_input event from #{inspect(player)}: #{inspect(event)}")
    # just do a genserver call lol
    {:noreply, socket}
  end
end
