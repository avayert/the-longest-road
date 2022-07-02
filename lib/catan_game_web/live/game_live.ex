defmodule CatanWeb.GameLive do
  use CatanWeb, :live_view

  require Logger

  alias Catan.GameCoordinator, as: GC

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    if GC.lobby_exists?(id) do
      {:ok, socket |> assign(:id, id) |> assign(:game, GC.get_lobby(id).game_pid )}  # this ought to be get_game I guess
    else
      {:ok, socket |> put_flash(:error, "No lobby with ID #{id} found.") |> redirect(to: "/")}
    end
  end

  @impl true
  def handle_event("player_input", params, %{assigns: %{game: game}} = socket) do  # I imagine I'm not supposed to be reaching into the assigns like this
    GenServer.cast(game, {:player_input, params})
    {:noreply, socket}
  end
end
