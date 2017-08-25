# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :ttl,
  ecto_repos: [Ttl.Repo]

# Configures the endpoint
config :ttl, Ttl.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SUN+M2Sp7XJAgV+CQ3SnDniZiQIX9Fpwn3uIiH/2UCPvtCHOVIfvXLEOWLUNZBph",
  render_errors: [view: Ttl.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Ttl.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :ttl, :generators,
  migration: true,
  binary_id: true

config :phoenix, :template_engines,
  drab: Drab.Live.Engine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
