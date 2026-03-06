defmodule KinoFLAME.RunnerCellTest do
  use ExUnit.Case, async: true

  import Kino.Test

  alias KinoFLAME.RunnerCell

  setup :configure_livebook_bridge

  describe "initialization with fly runtime" do
    test "with empty attributes" do
      # We set name to make sure it's deterministic, and we set
      # initialize_pythonx to test the base case.
      attrs = %{"name" => "runner", "initialize_pythonx" => false}

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               """
               Kino.start_child(
                 {FLAME.Pool,
                  name: :runner,
                  code_sync: [start_apps: true, sync_beams: Kino.beam_paths(), compress: false],
                  min: 0,
                  max: 1,
                  max_concurrency: 10,
                  boot_timeout: :timer.minutes(3),
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAME.FlyBackend,
                     cpu_kind: "shared",
                     cpus: 1,
                     memory_mb: 1024,
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
        "compress" => true,
        "fly_cpu_kind" => "performance",
        "fly_cpus" => 2,
        "fly_memory_gb" => 2,
        "fly_gpu_kind" => "a100-pcie-40gb",
        "fly_gpus" => 2,
        "fly_envs" => ["MY_TOKEN"],
        "initialize_pythonx" => false
      }

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               """
               Kino.start_child(
                 {FLAME.Pool,
                  name: :my_runner,
                  code_sync: [start_apps: true, sync_beams: Kino.beam_paths(), compress: true],
                  min: 2,
                  max: 3,
                  max_concurrency: 15,
                  boot_timeout: :timer.minutes(3),
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
                     env: %{
                       "LIVEBOOK_COOKIE" => Node.get_cookie(),
                       "MY_TOKEN" => System.fetch_env!("MY_TOKEN")
                     }}}
               )\
               """
    end

    test "with pythonx" do
      attrs = %{"name" => "runner", "initialize_pythonx" => true}

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               """
               Kino.start_child(
                 {FLAME.Pool,
                  name: :runner,
                  code_sync: [
                    start_apps: true,
                    sync_beams: Kino.beam_paths(),
                    compress: false,
                    copy_paths: Pythonx.install_paths()
                  ],
                  min: 0,
                  max: 1,
                  max_concurrency: 10,
                  boot_timeout: :timer.minutes(3),
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAME.FlyBackend,
                     cpu_kind: "shared",
                     cpus: 1,
                     memory_mb: 1024,
                     env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()} |> Map.merge(Pythonx.install_env())}}
               )\
               """
    end
  end

  describe "initialization with kubernetes runtime" do
    test "with empty attributes" do
      # We set name to make sure it's deterministic, and we set
      # initialize_pythonx to test the base case.
      attrs = %{"name" => "runner", "initialize_pythonx" => false}
      System.put_env("KUBERNETES_SERVICE_HOST", "some-value")

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               ~s'''
               import YamlElixir.Sigil

               manifest = ~y"""
               apiVersion: v1
               kind: Pod
               metadata:
                 generateName: livebook-flame-runner-
               spec:
                 containers:
                   - name: livebook-runtime
               """

               Kino.start_child(
                 {FLAME.Pool,
                  name: :runner,
                  code_sync: [start_apps: true, sync_beams: Kino.beam_paths(), compress: false],
                  min: 0,
                  max: 1,
                  max_concurrency: 10,
                  boot_timeout: :timer.minutes(3),
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAMEK8sBackend, manifest: manifest, env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()}}}
               )\
               '''
    after
      System.delete_env("KUBERNETES_SERVICE_HOST")
    end

    test "restores source code from attrs" do
      attrs = %{
        "backend" => "k8s",
        "name" => "my_runner",
        "min" => 2,
        "max" => 3,
        "max_concurrency" => 15,
        "compress" => true,
        "k8s_pod_template" => "some_template",
        "initialize_pythonx" => false
      }

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               ~s'''
               import YamlElixir.Sigil

               manifest = ~y"""
               some_template
               """

               Kino.start_child(
                 {FLAME.Pool,
                  name: :my_runner,
                  code_sync: [start_apps: true, sync_beams: Kino.beam_paths(), compress: true],
                  min: 2,
                  max: 3,
                  max_concurrency: 15,
                  boot_timeout: :timer.minutes(3),
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAMEK8sBackend, manifest: manifest, env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()}}}
               )\
               '''
    end

    test "with pythonx" do
      attrs = %{"backend" => "k8s", "name" => "runner", "initialize_pythonx" => true}

      {_kino, source} = start_smart_cell!(RunnerCell, attrs)

      assert source ==
               ~s'''
               import YamlElixir.Sigil

               manifest = ~y"""
               apiVersion: v1
               kind: Pod
               metadata:
                 generateName: livebook-flame-runner-
               spec:
                 containers:
                   - name: livebook-runtime
               """

               Kino.start_child(
                 {FLAME.Pool,
                  name: :runner,
                  code_sync: [
                    start_apps: true,
                    sync_beams: Kino.beam_paths(),
                    compress: false,
                    copy_paths: Pythonx.install_paths()
                  ],
                  min: 0,
                  max: 1,
                  max_concurrency: 10,
                  boot_timeout: :timer.minutes(3),
                  idle_shutdown_after: :timer.minutes(1),
                  timeout: :infinity,
                  track_resources: true,
                  backend:
                    {FLAMEK8sBackend,
                     manifest: manifest,
                     env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()} |> Map.merge(Pythonx.install_env())}}
               )\
               '''
    end
  end

  test "updates source on field update" do
    {kino, _source} = start_smart_cell!(RunnerCell, %{})

    push_event(kino, "update_field", %{"field" => "min", "value" => "5"})

    assert_broadcast_event(kino, "update", %{"fields" => %{"min" => 5}})

    assert_smart_cell_update(kino, %{"min" => 5}, source)
    assert source =~ "min: 5"
  end

  test "when available env vars change notifies the client" do
    {kino, _source} = start_smart_cell!(RunnerCell, %{})

    System.put_env("TEST_NEW_ENV_VAR", "1")

    env = Code.env_for_eval([])
    RunnerCell.scan_binding(kino.pid, [], env)

    push_event(kino, "update_field", %{"field" => "min", "value" => "5"})

    assert_broadcast_event(kino, "set_all_envs", %{"all_envs" => all_envs})
    assert "TEST_NEW_ENV_VAR" in all_envs
  end
end
