defmodule Ttl.Repo.Migrations.CreateTtl.Things.Object do
  use Ecto.Migration

  def up do 
    create table(:things_objects, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :path, {:array, :uuid}
      add :level, :integer
      add :title, :text
      add :content, :text
      add :blob, :binary
      add :closed, :utc_datetime
      add :scheduled, :utc_datetime
      add :deadline, :utc_datetime
      add :state, :string
      add :priority, :string
      add :version, :integer
      add :defer_count, :integer
      add :min_time_needed, :integer
      add :time_spent, :integer
      add :time_left, :integer
      add :permissions, :integer
      add :document_id, references(:things_documents, on_delete: :nothing, type: :binary_id)

      #timestamps()
      #add :inserted_at, :timestamp, [default: "CURRENT_TIMESTAMP"]
      #add :updated_at, :timestamp, [default: "CURRENT_TIMESTAMP"]
    end

    create index(:things_objects, [:document_id])

    execute """
      alter table things_objects add column inserted_at timestamp not null default now();
    """
    execute """
      alter table things_objects add column updated_at timestamp not null default now();
    """
  end
  def down do
    execute """
      drop table things_objects;
    """
  end
end
