defmodule Ttl.Repo.Migrations.CreateTtl.Accounts.User do
  use Ecto.Migration

  def change do
    create table(:accounts_users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string
      add :access_token, :string

      timestamps()
    end
    create unique_index(:accounts_users, [:access_token])
    create unique_index(:accounts_users, [:email])

  end
end
