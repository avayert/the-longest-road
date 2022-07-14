defmodule CatanWeb.Components.LobbyOption do
  # phoenix does not dispatch phx-change for individual components, so it's kinda forcing you to use the whole form
  # model of doing things. I do not know how the changeset stuff would work with (presumably) dynamic options either :)
  #
  # It's also why this is just a function component instead of being a full-fledged live component, since presumably
  # this only needs to be used in exactly one template it makes most sense to just put it directly into there and
  # handle the state in the view itself.

  use Phoenix.Component
  use Phoenix.HTML

  def option(%{option: %{type: :range, values: min..max}} = assigns) do
    ~H"""
    <%= label @form, @option.name, @option.display_name %>
    <%= number_input @form, @option.name, min: min, max: max, value: @option.default %>
    """
  end

  def option(%{option: %{type: :select}} = assigns) do
    ~H"""
    <%= label @form, @option.name %>
    <%= select @form, @option.name, @option.values, selected: @option.default %>
    """
  end

  def option(%{option: %{type: :toggle}} = assigns) do
    ~H"""
    <%= label @form, @option.name %>
    <%= checkbox @form, @option.name, checked_value: @option.default %>
    """
  end

  def option(%{option: %{type: :text}} = assigns) do
    ~H"""
    <%= label @form, @option.name %>
    <%= text_input @form, @option.name, value: @option.default, phx_change: "lobby_name_changed" %>
    """
  end
end
