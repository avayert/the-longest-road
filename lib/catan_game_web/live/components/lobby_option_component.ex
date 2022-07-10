defmodule CatanWeb.Components.LobbyOption do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="lobby_option">
      <%= inspect(@option) %>
    </div>
    """
  end
end
