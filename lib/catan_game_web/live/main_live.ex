defmodule CatanWeb.MainLive do
  use CatanWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("create_lobby", _params, %{assigns: %{}} = socket) do
    {:noreply, socket}
  end
end
