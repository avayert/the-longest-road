defmodule CatanWeb.LobbyController do
  alias Catan.Lobby
  use CatanWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def join(conn, %{ "id" => id }) do
    case Lobby.find(id) do
      :nil ->
        conn
          |> put_flash(:error, "No lobby with ID #{id} found.")
          |> redirect(to: Routes.lobby_path(conn, :index))
      _ ->
        render(conn, "lobby.html", id: id)
    end
  end

  def create(conn, %{ "id" => id }) do
    Lobby.create(id)
    redirect(conn, to: Routes.lobby_path(conn, :join, id))
  end
end
