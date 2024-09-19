defmodule KinoFLAME.RunnerCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/runner_cell", entrypoint: "build/main.js"
  use Kino.JS.Live
  use Kino.SmartCell, name: "FLAME runner cell"

  @text_fields ["name", "backend"]
  @number_fields ["min", "max", "max_concurrency"] ++ ["fly_cpus", "fly_memory_gb", "fly_gpus"]
  @default_pod_template """
  apiVersion: v1
  kind: Pod
  metadata:
    generateName: livebook-flame-runner-
  spec:
    containers:
      - name: livebook-runtime
        env:
          - name: LIVEBOOK_COOKIE
            value: \#{Node.get_cookie()}\
  """

  @impl true
  def init(attrs, ctx) do
    backend = attrs["backend"] || default_backend()

    fields = %{
      "name" => Kino.SmartCell.prefixed_var_name("runner", attrs["name"]),
      "backend" => backend,
      "min" => attrs["min"] || 0,
      "max" => attrs["max"] || 1,
      "compress" => Map.get(attrs, "compress", false),
      "max_concurrency" => attrs["max_concurrency"] || 10,
      "fly_cpus" => attrs["fly_cpus"] || 1,
      "fly_cpu_kind" => attrs["fly_cpu_kind"] || "shared",
      "fly_memory_gb" => attrs["fly_memory_gb"] || 1,
      "fly_gpu_kind" => attrs["fly_gpu_kind"],
      "fly_gpus" => attrs["fly_gpus"],
      "fly_envs" => attrs["fly_envs"] || []
    }

    k8s_pod_template = attrs["k8s_pod_template"] || @default_pod_template

    ctx =
      assign(
        ctx,
        fields: fields,
        warnings: warnings(),
        all_envs: [],
        k8s_pod_template: k8s_pod_template,
        missing_dep: missing_dep(fields),
        missing_livebook_cookie: missing_livebook_cookie(k8s_pod_template)
      )

    {:ok, ctx, editor: [source: k8s_pod_template, language: "yaml", visible: backend == "k8s"]}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields,
      warnings: ctx.assigns.warnings,
      all_envs: ctx.assigns.all_envs,
      missing_dep: ctx.assigns.missing_dep,
      missing_livebook_cookie: ctx.assigns.missing_livebook_cookie
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
  def handle_event("update_field", %{"field" => "backend", "value" => value}, ctx) do
    ctx =
      ctx
      |> reconfigure_smart_cell(editor: [visible: value == "k8s"])
      |> update_field("backend", value)

    missing_dep = missing_dep(ctx.assigns.fields)

    ctx =
      if missing_dep == ctx.assigns.missing_dep do
        ctx
      else
        broadcast_event(ctx, "missing_dep", %{"dep" => missing_dep})
        assign(ctx, missing_dep: missing_dep)
      end

    {:noreply, ctx}
  end

  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    {:noreply, update_field(ctx, field, value)}
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

  @impl true
  def handle_editor_change(source, ctx) do
    missing_livebook_cookie = missing_livebook_cookie(source)

    if missing_livebook_cookie != ctx.assigns.missing_livebook_cookie do
      broadcast_event(ctx, "missing_livebook_cookie", %{"is_missing" => missing_livebook_cookie})
    end

    {:ok,
     assign(ctx,
       k8s_pod_template: source,
       missing_livebook_cookie: missing_livebook_cookie
     )}
  end

  defp update_field(ctx, field, value) do
    updated_fields = to_updates(field, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    ctx
  end

  defp default_backend() do
    if System.get_env("KUBERNETES_SERVICE_HOST"), do: "k8s", else: "fly"
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
  def to_attrs(%{assigns: %{fields: fields, k8s_pod_template: k8s_pod_template}}) do
    fields = Map.put(fields, "k8s_pod_template", k8s_pod_template)

    shared_keys = ["backend", "name", "min", "max", "max_concurrency", "compress"]

    backend_keys =
      case fields["backend"] do
        "k8s" ->
          ~w|k8s_pod_template|

        "fly" ->
          ~w|fly_cpus fly_cpu_kind fly_memory_gb fly_gpu_kind fly_gpus fly_envs|
      end

    Map.take(fields, shared_keys ++ backend_keys)
  end

  @impl true
  def to_source(attrs) do
    shared_required_keys = ["name", "min", "max", "max_concurrency", "compress"]

    required_keys =
      case attrs["backend"] do
        "fly" ->
          shared_required_keys ++ ["fly_cpu_kind", "fly_cpus", "fly_memory_gb"]

        "k8s" ->
          shared_required_keys
      end

    if all_fields_filled?(attrs, required_keys) do
      attrs |> to_quoted() |> Kino.SmartCell.quoted_to_string()
    else
      ""
    end
  end

  defp all_fields_filled?(attrs, keys) do
    not Enum.any?(keys, fn key -> attrs[key] in [nil, ""] end)
  end

  defp to_quoted(%{"backend" => "fly"} = attrs) do
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

    backend_ast =
      quote do
        {FLAME.FlyBackend,
         [
           unquote_splicing(specs_opts),
           env: unquote(env)
         ]}
      end

    to_quoted_pool(attrs, backend_ast)
  end

  defp to_quoted(%{"backend" => "k8s"} = attrs) do
    multiline_k8s_pod_template =
      {:sigil_y, [delimiter: ~S["""]], [{:<<>>, [], [attrs["k8s_pod_template"] <> "\n"]}, []]}

    backend_ast =
      quote do: {FLAMEK8sBackend, runner_pod_tpl: pod_template}

    quote do
      import YamlElixir.Sigil
      pod_template = unquote(multiline_k8s_pod_template)
      unquote(to_quoted_pool(attrs, backend_ast))
    end
  end

  defp to_quoted_pool(attrs, quoted_backend) do
    # Note we use a longer :boot_timeout in case a CUDA-based Docker
    # image is involved. Those images are generally large, so it takes
    # a while to pull them, unless they are already in the Fly cache.

    quote do
      Kino.start_child(
        {FLAME.Pool,
         name: unquote(String.to_atom(attrs["name"])),
         code_sync: [
           start_apps: true,
           sync_beams: Kino.beam_paths(),
           compress: unquote(attrs["compress"])
         ],
         min: unquote(attrs["min"]),
         max: unquote(attrs["max"]),
         max_concurrency: unquote(attrs["max_concurrency"]),
         boot_timeout: :timer.minutes(3),
         idle_shutdown_after: :timer.minutes(1),
         timeout: :infinity,
         track_resources: true,
         backend: unquote(quoted_backend)}
      )
    end
  end

  def warnings() do
    %{
      "no_k8s" => !System.get_env("KUBERNETES_SERVICE_HOST"),
      "no_fly" => !System.get_env("FLY_PRIVATE_IP"),
      "no_fly_token" => !System.get_env("FLY_API_TOKEN")
    }
  end

  defp missing_dep(%{"backend" => "k8s"}) do
    backend = Code.ensure_loaded?(FLAMEK8sBackend)
    yaml_elixir = Code.ensure_loaded?(YamlElixir)

    cond do
      backend and yaml_elixir ->
        nil

      backend ->
        ~s/{:yaml_elixir, "~> 2.0"}/

      yaml_elixir ->
        ~s/{:flame_k8s_backend, "~> 0.5"}/

      true ->
        ~s/{:flame_k8s_backend, "~> 0.5"}, {:yaml_elixir, "~> 2.0"}/
    end
  end

  defp missing_dep(_fields), do: nil

  defp missing_livebook_cookie(k8s_pod_template) do
    not (k8s_pod_template =~ ~r|\sLIVEBOOK_COOKIE\s|)
  end
end
