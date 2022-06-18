defmodule CatanWeb.MainLive do
  use CatanWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
