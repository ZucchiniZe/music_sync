defmodule MusicSync.APISigMiddlewareTest do
  use ExUnit.Case, async: true

  alias MusicSync.Middleware.APISignature

  @valid_params [
    api_key: "api_key",
    artist: "bon iver",
    method: "track.love",
    sk: "session_key",
    track: "hey ma"
  ]

  test "sign_query/1 should hash the parameters and add the hash + json" do
    signed = APISignature.sign_query(%Tesla.Env{query: @valid_params})

    assert Keyword.keys(signed.query) == Keyword.keys(@valid_params) ++ [:api_sig, :format]
    assert signed.query[:api_sig] == "5ef98872e38bf29ca4d5c1ffd23f79a6"
    assert signed.query[:format] == "json"
  end
end
