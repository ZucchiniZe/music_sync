defmodule MusicSync.Middleware.Cache do
  @moduledoc """
  Caching middleware for spotify, potentially adaptable to other situations.
  Caches the etag of a response and the response itself with a prefix. follows
  the `private` Cache-Control directive.

  ## Notes

  we set the headers before the request runs and then if we get a 304 back then
  grab the response from the cache.

  ## Options

  a single atom containing the value to look up in the opts field in the tesla
  struct
  """
  @behaviour Tesla.Middleware
  @cache Application.compile_env!(:music_sync, [MusicSync.Spotify, :cache])

  def call(env, next, ident \\ nil) do
    env
    |> set_headers(ident)
    |> Tesla.run(next)
    |> check_etag(ident)
  end

  defp set_headers(env, ident) do
    # get the etag for the specific user and url from the cache and set the
    # If-None-Match header with the etag wrapped in quotes. if the etag doesn't
    # exist then just continue on with the request.
    key = "etag:" <> url_key(env, ident)
    etag = Cachex.get!(@cache, key)

    if etag do
      Tesla.put_header(env, "if-none-match", etag)
    else
      env
    end
  end

  defp check_etag(env, ident) do
    # if the etag header exists then handle the response otherwise continue
    {:ok, %Tesla.Env{headers: headers}} = env

    if List.keymember?(headers, "etag", 0) do
      handle_response(env, ident)
    else
      env
    end
  end

  # grab the response from the cache and return that & potentially refresh the key
  defp handle_response({:ok, %Tesla.Env{status: 304} = env}, ident) do
    key = "response:" <> url_key(env, ident)
    {:ok, exists} = Cachex.exists?(@cache, key)

    # TODO: figure out what to do if the key doesn't exist in the db - not sure
    # if this is an actual worry
    # the status gets cached as well so we don't need to rewrite it to 200
    if exists, do: Cachex.get(@cache, key)
  end

  # set cache value for the etag and the response to the body of the request
  defp handle_response({:ok, %Tesla.Env{status: 200} = env}, ident) do
    base_key = url_key(env, ident)
    {_, etag} = List.keyfind(env.headers, "etag", 0)

    pairs = [
      {"etag:" <> base_key, etag},
      {"response:" <> base_key, Tesla.put_opt(env, :cached, true)}
    ]

    Cachex.put_many(@cache, pairs, ttl: :timer.hours(72))

    {:ok, env}
  end

  defp handle_response(env, _ident), do: env

  defp url_key(env, nil), do: env.url |> Tesla.build_url(env.query)

  defp url_key(env, ident) do
    url = Tesla.build_url(env.url, env.query)

    "#{env.opts[ident]}:#{url}"
  end
end
