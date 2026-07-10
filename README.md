# El Nino

Discord music player bot. Powered by Elixir with Nostrum.

A bot is capable of working on multiple servers at once. Unstable feature.

> [!WARNING]
> This project prioritizes adding new features over improving and maintaining existing ones right now. Errors are expected, especially in long running actions, less popular commands and unlikely state scenarios.

## Dependencies

- [Nostrum](https://github.com/Kraigie/nostrum) - Discord API wrapper
- [WebSockex](https://github.com/dominicletz/websockex) - WebSockets handling
- [Req](https://github.com/wojtekmach/req) - HTTP requests handling
- [Qex](https://github.com/princemaple/elixir-queue) - Erlang's `:queue` wrapper

### LavaLink

The bot delegates music playback to a separate [LavaLink](https://github.com/lavalink-devs/Lavalink) instance, created via [Docker Compose](lavalink/).

## How to run

Before running the bot, ensure you have `docker` and `docker compose` installed. [Docker Desktop](https://docs.docker.com/desktop/) is recommended, however you may also install standalone [Docker Engine](https://docs.docker.com/engine/install/) for headless systems.

1. Create your own [Discord Application](https://discord.com/developers/home) (bot), retrieve its Application Token. [Official docs](https://docs.discord.com/developers/quick-start/getting-started#step-1-creating-an-app)
2. Copy `.yaml` configuration files from [Lavalink Folder](lavalink/).
3. Setup Environment Variables:

   - Necessary:

   ```sh
   export DISCORD_TOKEN=<discord_token> # Application Token of your bot.
   ```

   - Optional:

   ```sh
   export YT_OAUTH_TOKEN=<youtube_token> # YouTube refresh token. Can be retrieved through LavaLink's instance's logs.
   ```

   [Official docs on the token](https://github.com/lavalink-devs/youtube-source#using-oauth-tokens) [3rd party instruction](https://docs.dcs.aitsys.dev/articles/modules/audio/lavalink_v4/setup)
4. Run the command in the same folder as the configuration files:

   ```sh
   docker compose up -d
   ```

> [!IMPORTANT]
> The compose file relies on a Docker Hub image. It may be updated inconsistently, therefore it is recommended to create your own using existing [Dockerfile](Dockerfile). After that update `bot: image: <your_image_name>` in [compose.yaml](lavalink/compose.yaml?plain=1#L25)

## Architecture

Currently the architecture consists of the main Nostrum Bot process communicating with the Discord API. Relevant commands create a pair of Song Manager (SM) and Song Queue (SQ) processes associated with a Guild (Server). A LavaLink instance is always active in a separate docker container. Each SM oversees its own LavaLink [Player](https://lavalink.dev/api/rest.html#player-api). LavaLink intercepts incoming VC connections and independently manages them. SM modifies and ultimately deletes a Player when needed.

![Architecture Diagram](readme/architecture_diagram.png)

## Current goals

- [X] Add basic music controls: adding songs, skipping, pausing \ resumig, leaving, clearing the queue
- [X] Add ability to add playlists to queue
- [ ] Add improved handling of commands: allow only users in VC to use commands, disallow some commands from being used by everyone
- [ ] Add ability to manage queues through interactions
- [ ] Allow bot to leave after some time of inactivity
- [ ] General: improve error handling
