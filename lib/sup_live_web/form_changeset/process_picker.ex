defmodule SupLiveWeb.FormChangeset.ProcessPicker do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field(:module_name, Ecto.Enum,
      values: [
        SupLive.ExampleWorkers.Count,
        SupLive.ExampleWorkers.CountFaulty,
        SupLive.ExampleWorkers.State,
        SupLive.ExampleWorkers.StateFaulty
      ]
    )

    field(:children, :integer)

    field(:strategy, Ecto.Enum,
      values: [
        :one_for_one,
        :one_for_all,
        :rest_for_one,
        :simple_one_for_one
      ]
    )

    field(:restart_type, Ecto.Enum,
      values: [
        :permanent,
        :temporary,
        :transient
      ]
    )

    field(:max_restarts, :integer)
  end

  def changeset(changeset \\ %__MODULE__{}, params) do
    changeset
    |> cast(params, [
      :module_name,
      :children,
      :max_restarts,
      :strategy,
      :restart_type
    ])
  end

  def new(params) do
    params
    |> changeset()
    |> apply_action(:insert)
  end
end
