defmodule MusicSync.Telemetry do
  @moduledoc """
  Heavily 'inspired' by `Finch.Telemetry`.
  """

  def start(event, meta \\ %{}, extra_measurements \\ %{}) do
    start_time = System.monotonic_time()

    :telemetry.execute(
      [:music_sync, event, :start],
      Map.merge(extra_measurements, %{system_time: System.system_time()}),
      meta
    )

    start_time
  end

  def stop(event, start_time, meta \\ %{}, extra_measurements \\ %{}) do
    end_time = System.monotonic_time()
    measurements = Map.merge(extra_measurements, %{duration: end_time - start_time})

    :telemetry.execute(
      [:music_sync, event, :stop],
      measurements,
      meta
    )
  end

  def event(event, measurements, meta) when is_atom(event) do
    :telemetry.execute([:music_sync, event], measurements, meta)
  end

  def event(event, measurements, meta) when is_list(event) do
    :telemetry.execute([:music_sync] ++ event, measurements, meta)
  end
end
