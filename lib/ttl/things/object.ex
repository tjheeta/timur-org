defmodule Ttl.Things.Object do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Things.Object


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "things_objects" do
    field :blob, :binary
    field :closed, :utc_datetime
    field :content, :string
    field :deadline, :utc_datetime
    field :defer_count, :integer
    field :level, :integer
    field :min_time_needed, :integer
    field :path, {:array, Ecto.UUID}
    field :permissions, :integer
    field :priority, :string
    field :scheduled, :utc_datetime
    field :state, :string
    field :time_left, :integer
    field :time_spent, :integer
    field :title, :string
    field :version, :integer
    field :document_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(%Object{} = object, attrs) do
    object
    |> cast(attrs, [:path, :level, :title, :content, :blob, :closed, :scheduled, :deadline, :state, :priority, :version, :defer_count, :min_time_needed, :time_spent, :time_left, :permissions])
    |> validate_required([:path, :level, :title, :content, :blob, :closed, :scheduled, :deadline, :state, :priority, :version, :defer_count, :min_time_needed, :time_spent, :time_left, :permissions])
  end
end
