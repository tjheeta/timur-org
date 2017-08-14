defmodule Ttl.Things.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Things.Tag


  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "things_tags" do
    field :tag, :string
    field :user_id, :binary_id

    timestamps()
  end

  @doc false
  def changeset(%Tag{} = tag, attrs) do
    tag
    |> cast(attrs, [:tag])
    |> validate_required([:tag])
  end
end
