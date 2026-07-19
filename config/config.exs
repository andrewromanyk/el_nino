import Config

config :el_nino,
  ElNino.Repo,
  database: "el_nino.db"

config :el_nino,
  ecto_repos: [ElNino.Repo]

config :nostrum,
  youtubedl: nil,
  streamlink: nil,
  voice_auto_connect: false

config :logger,
  # needed to not drop error logs
  handle_sasl_reports: true
