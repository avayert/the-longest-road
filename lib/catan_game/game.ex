defmodule Catan.Game do
  @moduledoc """
  TODO
  """

  use GenServer, restart: :transient

  require Logger

  alias Catan.Engine.Directive
  require Directive

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
  @type dispatch_result :: Catan.Engine.GameMode.dispatch_result()
  @type tick_result ::
          {:ok, Directive.stack(), game_state()}
          | {:error, atom() | {atom(), term()}, game_state()}

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

    {_, directive, _} = Enum.find(mode_inits, fn {:ok, dir, _state} -> dir end)

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

  defp push_directive(state, directive) when is_struct(directive, Directive) do
    Map.update!(state, :game_directives, fn cur -> [directive | cur] end)
  end

  defp push_directive(state, directive) do
    push_directive(state, Directive.new(directive))
  end

  defp put_directives(state, directives) do
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
      dispatch(state, state.game_directives)
      |> case do
        {dir, new_state} when is_struct(dir, Directive) ->
          {:ok, [dir], new_state}

        {[dir | _] = dirs, new_state} when is_struct(dir, Directive) ->
          {:ok, dirs, new_state}

        {[], new_state} ->
          {:error, :no_directives, new_state}

        nil ->
          {:error, :no_gamemode_match, state}

        wtf ->
          {:error, {:unknown_result, wtf}, state}
      end
      |> case do
        {:ok, new_directives, new_state} ->
          Logger.info("Resolved, game tick done")
          Logger.info("Got new directives: #{inspect(new_directives)}")

          new_state = put_directives(new_state, new_directives)
          {:ok, new_directives, new_state}

        {:error, why, _state} = result ->
          Logger.error("Error doing dispatch: #{why}")
          result
      end
    rescue
      FunctionClauseError ->
        Logger.error(
          "No function clause found for #{inspect(state.game_directives)}\n" <>
            Catan.Utils.get_stacktrace()
        )
        {:error, :no_clause, state}

      e ->
        Logger.error("Unhandled error " <> Exception.format(:error, e, __STACKTRACE__))
        {:error, e, state}
    end
  end

  @spec dispatch(
          state :: game_state(),
          directives :: DirectiveStack.t()
        ) :: any()
  def dispatch(state, directives) do
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

        {:error, error, state} ->
          Logger.error("Tick returned error: #{inspect(error)}")
          state |> push_directive(game_error: error)
          # TODO: maybe change this to [error: :(old directive)]?
      end

    case state.game_directives do
      [%Directive{op: {:action, _}} | _] ->
        {:noreply, state, {:continue, :action}}

      [%Directive{op: {:phase, _}} | _] = cur_dirs ->
        Logger.info("End of the line for #{inspect(cur_dirs)}")
        {:noreply, state}

      [%Directive{op: {:game_error, error}} | _] ->
        Logger.error("Game loop failed with error: #{error}")
        {:noreply, state}

      :error ->
        Logger.error(
          "Bad(?) directive :error returned from:\n" <>
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
