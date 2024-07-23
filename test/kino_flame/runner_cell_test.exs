defmodule KinoFLAME.RunnerCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias KinoFLAME.RunnerCell

  setup :configure_livebook_bridge

  describe "initialization" do
    test "with empty attributes" do
      # We only set name to make sure it's deterministic
      attrs = %{"name" => "runner"}

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               """
               Kino.start_child(
                 {FLAME.Pool,
                  name: :runner,
                  code_sync: [start_apps: true, copy_paths: true, sync_beams: Kino.beam_paths()],
                  min: 0,
                  max: 1,
                  max_concurrency: 10,
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAME.FlyBackend,
                     cpu_kind: "shared",
                     cpus: 1,
                     memory_mb: 1024,
                     token: System.fetch_env!("LB_FLY_API_TOKEN"),
                     env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()}}}
               )\
               """
    end

    test "restores source code from attrs" do
      attrs = %{
        "name" => "my_runner",
        "min" => 2,
        "max" => 3,
        "max_concurrency" => 15,
        "fly_cpu_kind" => "performance",
        "fly_cpus" => 2,
        "fly_memory_gb" => 2,
        "fly_gpu_kind" => "a100-pcie-40gb",
        "fly_gpus" => 2,
      }

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               """
               Kino.start_child(
                 {FLAME.Pool,
                  name: :my_runner,
                  code_sync: [start_apps: true, copy_paths: true, sync_beams: Kino.beam_paths()],
                  min: 2,
                  max: 3,
                  max_concurrency: 15,
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAME.FlyBackend,
                     cpu_kind: "performance",
                     cpus: 2,
                     memory_mb: 2048,
                     gpu_kind: "a100-pcie-40gb",
                     gpus: 2,
                     token: System.fetch_env!("LB_FLY_API_TOKEN"),
                     env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()}}}
               )\
               """
    end
  end

  test "updates source on field update" do
    {kino, _source} = start_smart_cell!(RunnerCell, %{})

    push_event(kino, "update_field", %{"field" => "min", "value" => "5"})

    assert_broadcast_event(kino, "update", %{"fields" => %{"min" => 5}})

    assert_smart_cell_update(kino, %{"min" => 5}, source)
    assert source =~ "min: 5"
  end
end
