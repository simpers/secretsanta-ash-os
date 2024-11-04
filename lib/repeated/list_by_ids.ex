defmodule Repeated.ListByIds do
  @moduledoc """
  A DSL for creating a standard list of `:read` actions for listing things.
  """

  @doc """
  Creates two new `:read` actions: `:list` and `:list_paginated`.
  """
  @spec list_by_ids() :: Macro.t()
  defmacro list_by_ids() do
    id_type = :nanoid

    quote do
      read :list_by_ids do
        primary? false

        argument :ids, {:array, unquote(id_type)} do
          allow_nil? false
        end

        quote do
          filter expr(id in ^arg(:ids))
        end
      end

      read :list_by_ids_paginated do
        primary? false
        pagination offset?: true, countable: :by_default, default_limit: 10

        argument :ids, {:array, unquote(id_type)} do
          allow_nil? false
        end

        quote do
          filter expr(id in ^arg(:ids))
        end
      end
    end
  end

  @doc false
  @spec __using__(opts :: Keyword.t()) :: Macro.t()
  defmacro __using__(_opts) do
    module = __MODULE__

    quote generated: true, location: :keep do
      require unquote(module)
      import unquote(module), only: [list_by_ids: 0]
    end
  end
end
