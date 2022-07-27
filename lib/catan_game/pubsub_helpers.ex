defmodule Catan.PubSub.Topics do
  @moduledoc "Topic helper functions for pubsub."

  @doc "lobbies"
  @spec lobbies() :: String.t()
  def lobbies,
    do: "lobbies"

  @doc "lobby:{id}"
  @spec lobby(id :: String.t()) :: String.t()
  def lobby(id) when is_binary(id),
    do: "lobby:#{id}"

  @doc "games"
  @spec games() :: String.t()
  def games,
    do: "games"

  @doc "game:{id}"
  @spec game(id :: String.t()) :: String.t()
  def game(id) when is_binary(id),
    do: "game:#{id}"
end

defmodule Catan.PubSub.Payloads do
  @moduledoc "Payload helper functions for pubsub."

  @type response :: {atom(), any()}

  @lobbies_actions [:new_lobby, :delete_lobby, :lobby_update, :lobbyinfo_update]

  @doc "`#{inspect(@lobbies_actions)}`"
  @spec lobbies(:new_lobby, data :: String.t()) :: response()
  def lobbies(:new_lobby = action, data) when is_binary(data) do
    {action, data}
  end

  @spec lobbies(:delete_lobby, data :: String.t()) :: response()
  def lobbies(:delete_lobby = action, data) when is_binary(data) do
    {action, data}
  end

  @spec lobbies(:lobby_update, data :: String.t()) :: response()
  def lobbies(:lobby_update = action, data) when is_binary(data) do
    {action, data}
  end

  @spec lobbies(:lobbyinfo_update, data :: Catan.LobbyInfo.t()) :: response()
  def lobbies(:lobbyinfo_update = action, data)
      when is_struct(data, Catan.LobbyInfo) do
    {action, data}
  end

  @lobby_actions [:lobby_update, :lobby_option_update, :player_join]

  @doc "`#{inspect(@lobby_actions)}`"
  def lobby(action, data) when action in @lobby_actions do
    {action, data}
  end

  @games_actions [:todo]

  @doc "`#{inspect(@games_actions)}`"
  def games(action, data) when action in @games_actions do
    {action, data}
  end

  @game_actions [:choices]

  @doc "`#{inspect(@game_actions)}`"
  def game(action, data) when action in @game_actions do
    {action, data}
  end
end

defmodule Catan.PubSub.Pubsub do
  @moduledoc "Helpers for pubsub functions."

  @doc "Shortcut for `Phoenix.PubSub.subscribe`"
  defmacro subscribe(topic) do
    quote do
      Phoenix.PubSub.subscribe(Catan.PubSub, unquote(topic))
    end
  end

  @doc "Shortcut for `Phoenix.PubSub.broadcast!`"
  defmacro broadcast(topic, payload) do
    quote do
      Phoenix.PubSub.broadcast!(Catan.PubSub, unquote(topic), unquote(payload))
    end
  end
end
