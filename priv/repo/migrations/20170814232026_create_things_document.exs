defmodule Ttl.Repo.Migrations.CreateTtl.Things.Document do
  use Ecto.Migration

  def change do
    create table(:things_documents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string
      add :metadata, :map
      add :objects, {:array, :uuid}
      add :user_id, references(:accounts_users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:things_documents, [:user_id])
  end
end
