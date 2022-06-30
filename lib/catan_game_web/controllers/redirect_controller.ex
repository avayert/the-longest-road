defmodule CatanWeb.RedirectController do
  use CatanWeb, :controller

  @doc """
  This is where we route /:id links to whatever
  """
  def route_id(conn, %{"id" => id} = _params) do
    # get game id and redirect to whatever or /
    IO.inspect("Redirecting to / (id #{id}")
    conn |> redirect(to: "/")
  end
end
