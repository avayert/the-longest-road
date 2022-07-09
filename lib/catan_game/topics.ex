defmodule Catan.PubSub.Topics do
  @moduledoc "Topic helper functions for pubsub."

  @doc "gc:lobbies"
  def lobbies,
    do: "gc:lobbies"

  @doc "gc:lobby:{id}"
  def lobby(id) when is_binary(id),
    do: "gc:lobby:#{id}"

  @doc "gc:games"
  def games,
    do: "gc:games"

  @doc "gc:game:{id}"
  def game(id) when is_binary(id),
    do: "gc:game:#{id}"
end
