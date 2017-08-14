defmodule Ttl.Repo.Migrations.CreateTtl.Things.Tag do
  use Ecto.Migration

  def change do
    create table(:things_tags, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :tag, :string
      add :user_id, references(:accounts_users, on_delete: :nothing, type: :binary_id)

      timestamps()
    end

    create index(:things_tags, [:user_id])
  end
end
