defmodule Ttl.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Ttl.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Ttl.Web.Endpoint, []),
      :hackney_pool.child_spec(
        :kinto_pool,
        [timeout: 15_000, max_connections: 100]
      )
      # Start your own worker by calling: Ttl.Worker.start_link(arg1, arg2, arg3)
      # worker(Ttl.Worker, [arg1, arg2, arg3]),
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Ttl.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
