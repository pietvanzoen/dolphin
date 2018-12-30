use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dolphin, DolphinWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :dolphin, date: FakeDate
config :dolphin, datetime: FakeDateTime
config :dolphin, github: FakeGithub
config :dolphin, twitter: FakeTwitter
config :dolphin, mastodon: FakeMastodon
config :dolphin, http_client: FakeHTTPoison

config :dolphin, :github_credentials,
  username: "jeffkreeftmeijer",
  repository: "updates"

config :dolphin, :twitter_credentials, username: "jkreeftmeijer"

config :dolphin, :mastodon_credentials, base_url: "https://mastodon.social"
