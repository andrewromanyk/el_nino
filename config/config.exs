import Config

config :nostrum,
  youtubedl: nil,
  streamlink: nil,
  voice_auto_connect: false

config :logger,
  # needed to not drop error logs
  handle_sasl_reports: true
