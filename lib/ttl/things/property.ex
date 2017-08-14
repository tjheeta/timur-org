defmodule Ttl.Things.Property do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Things.Property


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "things_properties" do
    field :key, :string
    field :value, :string
    field :object_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(%Property{} = property, attrs) do
    property
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end
end
