defmodule Catan.Utils do
  @moduledoc false

  @spec update_map(map :: map(), options :: keyword()) :: map()
  @doc "Updates a map or struct with options from a keyword list"
  def update_map(map, options)
      when is_map(map) and (is_list(options) or is_map(options)) do
    #
    for {k, v} <- options, reduce: map do
      acc -> Map.replace(acc, k, v)
    end
  end
end
