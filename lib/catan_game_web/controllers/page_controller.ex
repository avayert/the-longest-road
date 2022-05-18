defmodule CatanWeb.PageController do
  use CatanWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
