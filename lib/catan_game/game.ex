defmodule Catan.Game do
  @moduledoc """
  TODO
  """

  use GenServer, restart: :transient
  # use GenServer, restart: :temporary

  require Logger

  alias Catan.Engine.Directive
  require Directive

  require Catan.Engine.GameMode.Helpers
  import Catan.Engine.GameMode.Helpers

  defmodule GameState do
    use TypedStruct

    typedstruct do
      field :lobby, Catan.Lobby.t(), enforce: true
      field :game_directives, [], default: []
      field :mode_states, %{module() => %{atom() => term()}}, default: %{}
      field :mode_tree, [], default: []
      field :map, any()
      field :turn_order, [any()], default: []
    end

    use Accessible

    def new(state), do: struct(__MODULE__, state)
  end

  @type game_state :: GameState.t()
  @type dispatch_result :: Catan.Engine.GameMode.dispatch_result()
  @type step_result ::
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
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Starting game: #{Keyword.get(opts, :lobby).id}"
    )

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

    # :ok = CatanWeb.Endpoint.subscribe("game:#{state.lobby.id}")
    :ok = Phoenix.PubSub.subscribe(Catan.PubSub, "game:#{state.lobby.id}")
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

  def send_pubsub(state, data) do
    Phoenix.PubSub.broadcast!(Catan.PubSub, "game:#{state.lobby.id}", data)
    state
  end

  def send_pubsub_choices(state, choices) do
    send_pubsub(state, {:choices, choices})
  end

  ## Actual functions

  @spec step_game(state :: game_state()) :: step_result()
  def step_game(state) do
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Stepping game state"
    )

    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Resolving #{inspect(state.game_directives, pretty: true)}"
    )

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
          Logger.info(
            "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
              "Resolved, game step done"
          )

          Logger.info(
            "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
              "Got new directives: #{inspect(new_directives, pretty: true)}"
          )

          new_state = put_directives(new_state, new_directives)
          {:ok, new_directives, new_state}

        {:error, why, _state} = result ->
          Logger.error(
            "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
              "Error doing dispatch: #{inspect(why)}"
          )

          result
      end
    rescue
      FunctionClauseError ->
        Logger.error(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "No function clause found for " <>
            "#{inspect(state.game_directives, pretty: true)}\n" <>
            Catan.Utils.get_stacktrace()
        )

        {:error, :no_clause, state}

      e ->
        Logger.error(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "Unhandled error " <> Exception.format(:error, e, __STACKTRACE__)
        )

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
          Logger.warning(
            "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
              "Hit :not_implemented for #{inspect(directives)}"
          )

          {:cont, nil}
      end
    end)
  end

  @impl true
  def handle_cast({:player_input, whatever}, state) do
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "TODO: Handling player input: #{inspect(whatever)}"
    )

    # TODO: goes to the gmaemode

    {:noreply, state, {:continue, :step}}
  end

  @impl true
  def handle_continue(:choices, state) do
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "TODO: choices stuff, awaiting event"
    )

    choices =
      state.game_directives
      |> List.first()
      |> get_in([:choices])

    Logger.info("Sending #{inspect(choices)}")
    send_pubsub_choices(state, choices)

    {:noreply, state}
  end

  @impl true
  def handle_continue(op, state) do
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Game got continue op: #{inspect(op)}"
    )

    state =
      case step_game(state) do
        {:ok, _directives, state} ->
          state

        {:error, error, state} ->
          Logger.error(
            "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
              "Step returned error: #{inspect(error)}"
          )

          state |> push_directive(game_error: error)
      end

    case state.game_directives do
      [%Directive{op: {:action, _}} | _] ->
        {:noreply, state, {:continue, :action}}

      [%Directive{op: {:phase, _}, choices: [_ | _]} | _] = cur_dirs ->
        Logger.info(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "Got phase choices #{inspect(cur_dirs)}"
        )

        {:noreply, state, {:continue, :choices}}

      # TODO: check for phase with no choices

      [%Directive{op: {:phase, _}} | _] = cur_dirs ->
        Logger.info(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "End of the line for #{inspect(cur_dirs)}"
        )

        {:noreply, state}

      [%Directive{op: {:game_error, error}} | _] ->
        Logger.error(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "Game loop failed with error: #{inspect(error)}, " <>
            "state was:\n#{inspect(state, pretty: true)}"
        )

        {:stop, :shutdown, state}

      :error ->
        Logger.error(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "Bad(?) directive :error returned from:\n" <>
            (Process.info(self(), :current_stacktrace)
             |> elem(1)
             |> Enum.drop(1)
             |> Exception.format_stacktrace())
        )

        {:stop, :shutdown, state}

      other ->
        Logger.warning(
          "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
            "unknown new directive: #{inspect(other)}"
        )

        {:noreply, state}
    end
  end

  @impl true
  def terminate(reason, state) do
    Logger.warning(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Game process #{inspect(self())} (id #{state.lobby.id}) is going down, " <>
        "reason: #{reason}, "
      # <>
      # "last known state:\n#{inspect(state, pretty: true)}"
    )

    # Logger.error("Stacktrace:\n" <> Exception.format_stacktrace(elem(reason, 1)))
  end

  @impl true
  def handle_info({:player_input, player, event}, state) do
    Logger.info(
      "[#{l_mod(1)}.#{l_fn()}:#{l_ln()}] " <>
        "Got player_input event from #{inspect(player)}: #{inspect(event)}"
    )

    # # # #
    # TODO: I also need a handle_input callback in gamemode huh
    # # # #

    # this might need to be a call if i need to do any validation or something
    GenServer.cast(self(), {:player_input, :todo})
    {:noreply, state}
  end

  @impl true
  def handle_info(stuff, state) do
    Logger.info("Unhandled info event with data: #{inspect(stuff, pretty: true)}")
    {:noreply, state}
  end

  #####

  def test_send_input(id, stuff) do
    Genserver.cast(Catan.GameCoordinator.via(id, :game), stuff)
  end
end
