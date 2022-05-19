defmodule Catan.Lobby do
  use Agent

  def start_link(_options) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def find(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def create(key) do
    Agent.update(__MODULE__, &Map.put(&1, key, 123))
  end

  def list do
    Agent.get(__MODULE__, &Map.keys(&1))
  end
end
