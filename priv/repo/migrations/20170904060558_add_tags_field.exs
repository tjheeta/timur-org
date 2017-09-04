defmodule Ttl.Repo.Migrations.AddTagsField do
  use Ecto.Migration

  def change do
    alter table(:things_objects) do
      add :tags, :string
    end
    create index(:things_objects, [:tags])

  end
end
