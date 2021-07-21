defmodule MusicSync.Middleware.Retry do
  @moduledoc """
  Takes inspiration from `Tesla.Middleware.Retry` but uses the specific headers
  that spotify requires for use with rate limiting
  """
  @behaviour Tesla.Middleware
  require Logger

  def call(env, next, _opts) do
    context = %{
      retries: 0,
      max_retries: 10
    }

    retry(env, next, context)
  end

  # if we hit max retries, just accept the error and move on
  def retry(env, next, %{max_retries: max, retries: max}) do
    Tesla.run(env, next)
  end

  # otherwise, if we hit the correct error, we retry
  def retry(env, next, context) do
    resp = Tesla.run(env, next)

    case should_retry?(resp) do
      {true, delay} ->
        :timer.sleep(delay * 1000)
        {:ok, raw_resp} = resp

        Logger.debug(
          "retrying #{inspect(raw_resp.url)} #{inspect(raw_resp.query)} in #{delay} seconds"
        )

        context = update_in(context, [:retries], &(&1 + 1))
        retry(env, next, context)

      false ->
        resp
    end
  end

  # we are rate limited if we get a 429 status code and then have to peek into
  # the Retry-After header to wait than many seconds
  defp should_retry?({:ok, %{status: 429} = resp}) do
    {_, delay} = List.keyfind(resp.headers, "retry-after", 0, "1")
    {true, String.to_integer(delay)}
  end

  defp should_retry?({:error, _}), do: {true, 1}
  defp should_retry?(_), do: false
end
