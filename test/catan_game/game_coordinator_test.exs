defmodule GameCoordinatorTest do
  use ExUnit.Case, async: true

  alias Catan.GameCoordinator, as: GC

  test "Lobby" do
    {id, lobby} = GC.create_lobby()
    assert id
    assert lobby
  end

  test "Start game" do
    {id, _lobby} = GC.create_lobby()
    assert {:ok, _id} = GC.start_game(id)
  end
end
