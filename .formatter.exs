[
  import_deps: [:ecto, :phoenix, :typed_struct],
  inputs: ["*.{ex,exs}", "priv/*/seeds.exs", "{config,lib,test}/**/*.{ex,exs}"],
  subdirectories: ["priv/*/migrations"],
  locals_without_parens: [state: 1, state: 2, action: 1, action: 2]
]
