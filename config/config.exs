import Config

config :nostrum,
  youtubedl: nil,
  streamlink: nil,
  voice_auto_connect: false

config :logger,
  handle_sasl_reports: true # needed to not drop error logs
