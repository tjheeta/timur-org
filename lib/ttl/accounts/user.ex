defmodule Ttl.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ttl.Accounts.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "accounts_users" do
    field :access_token, :string
    field :email, :string
    field :api_key, :string

    timestamps()
  end

  defp maybe_downcase_email(changeset) do
    case changeset.changes[:email] do
      nil -> changeset
      _ -> update_change(changeset, :email, &String.downcase/1)
    end
  end

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:email, :access_token])
    |> validate_required([:email])
    #|> update_change(:email, &String.downcase/1)
    |> maybe_downcase_email
    |> unique_constraint(:email)
    |> unique_constraint(:access_token)
  end

  def verify_session(access_token) do
    case Ttl.Accounts.get_user_by_token!(access_token) do
      nil ->
        {:error, "notoken"}
      user ->
        # why does phx not put everything in unixtime into ecto?
        if Timex.diff(Timex.now |> Timex.to_naive_datetime, user.updated_at) / 1000000 < 300 do
          {:ok, user}
        else
          {:error, "timeout"}
        end
    end
  end

  def create_session(params) do
     email = String.downcase(params["email"])
     case Ttl.Accounts.get_user_by_email!(email) do
        nil -> %User{email: email}
        user -> user
     end
     |> changeset(params)
     |> generate_access_token
     |> Ttl.Accounts.update_user
  end

  @doc false
  defp generate_access_token(struct) do
    token = SecureRandom.hex(30)

    case Ttl.Accounts.get_user_by_token!(token) do
      nil ->
        put_change(struct, :access_token, token)
      _ ->
        generate_access_token(struct)
    end
  end
end
