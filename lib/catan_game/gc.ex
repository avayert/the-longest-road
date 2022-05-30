defmodule Catan.GameCoordinator do
  use GenServer, restart: :transient

  def init(args) do
    {:ok, args}
  end
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
