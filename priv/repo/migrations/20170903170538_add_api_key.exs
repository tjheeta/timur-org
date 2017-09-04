defmodule Ttl.Repo.Migrations.AddApiKey do
  use Ecto.Migration

  def change do
    alter table(:accounts_users) do
      add :api_key, :string
    end
    create index(:accounts_users, [:api_key])
  end
end
