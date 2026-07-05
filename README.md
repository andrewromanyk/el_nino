# ElNino

Discord bot for playing music in Voice Chat in Elixir.

Currently a single bot instance can work only on a single server.

## Dependencies

- [Nostrum](https://github.com/Kraigie/nostrum)
- [WebSockex](https://github.com/dominicletz/websockex)
- [Req](https://github.com/wojtekmach/req)
- [Qex](https://github.com/princemaple/elixir-queue)

### LavaLink

The bot delegate music playback to a separate [LavaLink](https://github.com/lavalink-devs/Lavalink) instance, created via [docker](lavalink/).
