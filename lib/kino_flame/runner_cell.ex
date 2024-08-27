defmodule KinoFLAME.RunnerCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/runner_cell", entrypoint: "build/main.js"
  use Kino.JS.Live
  use Kino.SmartCell, name: "FLAME runner cell"

  @text_fields ["name"]
  @number_fields ["min", "max", "max_concurrency"] ++ ["fly_cpus", "fly_memory_gb", "fly_gpus"]

  @impl true
  def init(attrs, ctx) do
    fields = %{
      "name" => Kino.SmartCell.prefixed_var_name("runner", attrs["name"]),
      "min" => attrs["min"] || 0,
      "max" => attrs["max"] || 1,
      "max_concurrency" => attrs["max_concurrency"] || 10,
      "fly_cpus" => attrs["fly_cpus"] || 1,
      "fly_cpu_kind" => attrs["fly_cpu_kind"] || "shared",
      "fly_memory_gb" => attrs["fly_memory_gb"] || 1,
      "fly_gpu_kind" => attrs["fly_gpu_kind"],
      "fly_gpus" => attrs["fly_gpus"],
      "fly_envs" => attrs["fly_envs"] || []
    }

    {:ok, assign(ctx, fields: fields, warning_type: warning_type(), all_envs: [])}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      warning_type: ctx.assigns.warning_type,
      all_envs: ctx.assigns.all_envs
    }

    {:ok, payload, ctx}
  end

  @impl true
  def scan_binding(pid, _binding, _env) do
    # We don't actually use the binding, but that's the best place to
    # check env vars, in case another evaluation set those
    all_envs = System.get_env() |> Map.keys() |> Enum.sort()
    send(pid, {:scan_binding_result, all_envs})
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(field, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
  end

  @impl true
  def handle_info({:scan_binding_result, all_envs}, ctx) do
    if all_envs == ctx.assigns.all_envs do
      {:noreply, ctx}
    else
      broadcast_event(ctx, "set_all_envs", %{"all_envs" => all_envs})
      {:noreply, assign(ctx, all_envs: all_envs)}
    end
  end

  defp to_updates(field, value) when field in @number_fields and is_binary(value) do
    value =
      case Integer.parse(value) do
        {n, ""} -> n
        _ -> nil
      end

    %{field => value}
  end

  defp to_updates(field, "") when field not in @text_fields, do: %{field => nil}

  defp to_updates(field, value), do: %{field => value}

  @impl true
  def to_attrs(ctx) do
    ctx.assigns.fields
  end

  @impl true
  def to_source(attrs) do
    required_keys =
      ["name", "min", "max", "max_concurrency"] ++
        ["fly_cpu_kind", "fly_cpus", "fly_memory_gb"]

    if all_fields_filled?(attrs, required_keys) do
      attrs |> to_quoted() |> Kino.SmartCell.quoted_to_string()
    else
      ""
    end
  end

  defp all_fields_filled?(attrs, keys) do
    not Enum.any?(keys, fn key -> attrs[key] in [nil, ""] end)
  end

  defp to_quoted(attrs) do
    specs_opts =
      [
        cpu_kind: attrs["fly_cpu_kind"],
        cpus: attrs["fly_cpus"],
        memory_mb: attrs["fly_memory_gb"] * 1024,
        gpu_kind: attrs["fly_gpu_kind"],
        gpus: attrs["fly_gpus"]
      ]
      |> Enum.reject(&(elem(&1, 1) == nil))

    envs =
      [
        {"LIVEBOOK_COOKIE",
         quote do
           Node.get_cookie()
         end}
      ] ++
        for env <- attrs["fly_envs"] do
          {env,
           quote do
             System.fetch_env!(unquote(env))
           end}
        end

    env = {:%{}, [], envs}

    # Note we use a longer :boot_timeout in case a CUDA-based Docker
    # image is involved. Those images are generally large, so it takes
    # a while to pull them, unless they are already in the Fly cache.

    quote do
      Kino.start_child(
        {FLAME.Pool,
         name: unquote(String.to_atom(attrs["name"])),
         code_sync: [start_apps: true, copy_paths: true, sync_beams: Kino.beam_paths()],
         min: unquote(attrs["min"]),
         max: unquote(attrs["max"]),
         max_concurrency: unquote(attrs["max_concurrency"]),
         boot_timeout: :timer.minutes(3),
         idle_shutdown_after: :timer.minutes(1),
         timeout: :infinity,
         track_resources: true,
         backend:
           {FLAME.FlyBackend,
            [
              unquote_splicing(specs_opts),
              env: unquote(env)
            ]}}
      )
    end
  end

  def warning_type() do
    cond do
      System.fetch_env("FLY_PRIVATE_IP") == :error ->
        :no_fly

      System.fetch_env("FLY_API_TOKEN") == :error ->
        :no_fly_token

      true ->
        nil
    end
  end
end
