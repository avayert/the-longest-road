defmodule CatanWeb.LobbyView do
  use CatanWeb, :view

  alias Catan.Lobby

  def list_lobbies do
    Lobby.list()
  end
end
