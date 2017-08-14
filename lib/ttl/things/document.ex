defmodule Ttl.Things.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Things.Document


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "things_documents" do
    field :name, :string
    field :objects, {:array, Ecto.UUID}
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> cast(attrs, [:name, :objects])
    |> validate_required([:name, :objects])
  end
end
