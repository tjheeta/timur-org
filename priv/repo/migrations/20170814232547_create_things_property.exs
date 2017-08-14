defmodule Ttl.Repo.Migrations.CreateTtl.Things.Property do
  use Ecto.Migration

  def change do
    create table(:things_properties, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :key, :string
      add :value, :string
      add :object_id, references(:things_objects, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:things_properties, [:object_id])
  end
end
