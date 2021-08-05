defmodule MusicSync.Middleware.RateLimit do
  @moduledoc """
  Rate limit all requests coming from a client using this middleware using
  [ExRated](https://github.com/grempe/ex_rated).

  Checks to see if request can be made, if not inspects and sleeps for the
  required amount according to the rules.

  ## Options

  Takes a keyword list for the following options:

  - `:per` - time in milliseconds for the window of requests
  - `:limit` - the number of requests to be made in the window defined by `:per`

  `:service` must also be set using the `Tesla.Middleware.Opts` middleware,
  """
  @behaviour Tesla.Middleware
  alias MusicSync.Telemetry

  # check rate for host
  def call(env, next, options) do
    host = Keyword.get(env.opts, :service)
    url = Tesla.build_url(env.url, env.query)

    # every 5 seconds, make only 10 requests
    limit = Keyword.get(options, :limit, 10)
    scale = Keyword.get(options, :per, 5_000)

    case ExRated.check_rate(host, scale, limit) do
      {:ok, _} ->
        Tesla.run(env, next)

      {:error, _} ->
        {tokens_used, tokens_left, wait, _, _} = ExRated.inspect_bucket(host, scale, limit)

        Telemetry.event(
          [:middleware, :rate_limit],
          %{requests_made: tokens_used, requests_left: tokens_left, required_wait: wait},
          %{host: host, url: url}
        )

        :timer.sleep(wait)
        Tesla.run(env, next)
    end
  end
end
