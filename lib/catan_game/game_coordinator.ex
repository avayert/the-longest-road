defmodule Catan.GameCoordinator do
  @moduledoc """
  Behold the enslaved pencil pusher turned genserver that manages setting up games
  and starting them.  This process encapsulates creating a new lobby (Game), putting
  players in that lobby, and handling their completion.  It also does stuff like
  reconnecting users, blah blah i'll finish this spiel later.
  """

  use GenServer, restart: :transient

  defmodule State do
    use TypedStruct

    typedstruct do
    end
  end

  @type via_tuple() :: {:via, module(), {module(), String.t()}}

  def start_link(_args) do
    GenServer.start_link(__MODULE__, %State{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @spec via(id :: String.t()) :: {:via, Registry, {GameRegistry, String.t()}}
  defp via(id) do
    {:via, Registry, {GameRegistry, id}}
  end

  @ignored_id_chars ~W(i I l O)

  @spec random_id(num :: pos_integer()) :: String.t()
  @doc "Generate a random [a-zA-Z] string (default length of 5)"
  def random_id(num \\ 5) when is_number(num) and num > 0 do
    Stream.concat(?a..?z, ?A..?Z)
    |> Stream.reject(fn ch -> ch in @ignored_id_chars end)
    # do not judge me you have no such authority
    |> Enum.shuffle()
    |> Enum.take_random(num)
    |> List.to_string()

    # Stream.concat(?a..?z)
    # |> Stream.reject(fn ch -> ch in ~w(l) end)
    # |> Enum.shuffle()
    # |> Enum.take(num)
    # |> List.to_string()
  end

  # testing stuff

  def handle_call({:test}) do
  end

  # genserver/pubsub impls

  # public api

end

########################
# @impl true
# def handle_call({:join_game, id, player}, _from, state) do
#   try do
#     :ok = GenServer.call(via_tuple(id), {:add_player, player})
#   catch
#     :exit, e -> Logger.warning("Couldn't join_game: #{inspect(e)}")
#   end
#   {:reply, id, state, {:continue, :tick}}
# end
# defp via_tuple(id) do
#   {:via, Registry, {GameRegistry, id}}
# end
