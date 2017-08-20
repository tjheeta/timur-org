defmodule Ttl.Things.Object do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Things.Object


  # NOTE - Don't autogenerate id for objects here, it overwrites anything passed in
  # NOTE - Need to generate them as part of the query
  #@primary_key {:id, :binary_id, autogenerate: true}
  @primary_key {:id, :binary_id, autogenerate: false}

  @foreign_key_type :binary_id
  schema "things_objects" do
    field :blob, :binary
    field :content, :string
    field :defer_count, :integer
    field :level, :integer
    field :min_time_needed, :integer
    field :path, {:array, Ecto.UUID}
    field :permissions, :integer
    field :priority, :string
    field :state, :string
    field :time_left, :integer
    field :time_spent, :integer
    field :title, :string
    field :version, :integer
    field :document_id, :binary_id
    field :properties, :map
    field :closed, :utc_datetime
    field :deadline, :utc_datetime
    field :scheduled, :utc_datetime
    field :scheduled_date_range, :integer
    field :scheduled_repeat_interval, :string
    field :scheduled_time_interval, :integer

    timestamps()
  end

  @doc false
  def changeset(%Object{} = object, attrs) do
    tmp = object
    |> cast(attrs, [:id, :document_id, :path, :level, :title, :content, :blob, :state, :priority, :version, :defer_count, :min_time_needed, :time_spent, :time_left, :permissions, :properties, :closed,  :deadline, :scheduled, :scheduled_date_range, :scheduled_repeat_interval, :scheduled_time_interval])
    |> validate_required([:id, :document_id, :version])
  end
end
