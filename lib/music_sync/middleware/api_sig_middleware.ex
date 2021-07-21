defmodule MusicSync.Middleware.APISigMiddleware do
  @moduledoc """
  Lastfm requires all the query parameters to be hashed together with your
  secret key and then appended when making any requests. This middleware
  automatically handles that.
  """
  @behaviour Tesla.Middleware
  @client_secret Application.get_env(:music_sync, MusicSync.Lastfm)[:client_secret]
  require Logger

  @impl Tesla.Middleware
  def call(env, next, _ptions) do
    env
    |> sign_query()
    |> Tesla.run(next)
  end

  defp sign_query(env) do
    query = env.query |> Enum.sort()

    api_sig =
      query
      |> Enum.map(fn {key, value} -> "#{key}#{value}" end)
      |> Enum.concat([@client_secret])
      |> Enum.join()

    api_sig =
      :crypto.hash(:md5, api_sig)
      |> Base.encode16(case: :lower)

    query = query ++ [api_sig: api_sig, format: "json"]

    Logger.debug("lastfm query: #{inspect(query)}")

    %Tesla.Env{env | query: query}
  end
end
