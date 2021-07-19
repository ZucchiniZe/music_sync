# MusicSync

Addressing the problem of spotify scrobbling to lastfm. The scrobblign works
fine but when you add a track to your library it doesn't get added to the loved
tracks on lastfm. This project aims to fix that.

## todo list

- setup user auth
  - use spotify or lastfm to authenticate instead of personal auth
- link user to accounts (using oauth?)
  - spotify
    - callback
  - lastfm
- sync libraries

## notes

have a `services` entry where you store the api keys associated with each user.
implement token refreshing for spotify thru this.

## phoenix info

To start your Phoenix server:

- Install dependencies with `mix deps.get`
- Create and migrate your database with `mix ecto.setup`
- Install Node.js dependencies with `npm install` inside the `assets` directory
- Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
