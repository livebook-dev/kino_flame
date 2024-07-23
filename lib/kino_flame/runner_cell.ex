defmodule KinoFLAME.RunnerCell do
  @moduledoc false

  use Kino.JS, assets_path: "lib/assets/runner_cell", entrypoint: "build/main.js"
  use Kino.JS.Live
  use Kino.SmartCell, name: "FLAME runner cell"

  @text_fields ["name"]
  @number_fields ["min", "max", "max_concurrency"] ++ ["fly_cpus", "fly_memory_gb"]

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
      "fly_gpu_kind" => attrs["fly_gpu_kind"]
    }

    {:ok, assign(ctx, fields: fields)}
  end

  @impl true
  def handle_connect(ctx) do
    payload = %{
      fields: ctx.assigns.fields
    }

    {:ok, payload, ctx}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, ctx) do
    updated_fields = to_updates(field, value)
    ctx = update(ctx, :fields, &Map.merge(&1, updated_fields))
    broadcast_event(ctx, "update", %{"fields" => updated_fields})
    {:noreply, ctx}
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
    # TODO try changing FLAME to use /.fly/api instead of :token
    quote do
      Kino.start_child(
        {FLAME.Pool,
         name: unquote(String.to_atom(attrs["name"])),
         code_sync: [start_apps: true, copy_paths: true, sync_beams: Kino.beam_paths()],
         min: unquote(attrs["min"]),
         max: unquote(attrs["max"]),
         max_concurrency: unquote(attrs["max_concurrency"]),
         idle_shutdown_after: :timer.minutes(1),
         timeout: :infinity,
         track_resources: true,
         backend:
           {FLAME.FlyBackend,
            cpu_kind: unquote(attrs["fly_cpu_kind"]),
            cpus: unquote(attrs["fly_cpus"]),
            memory_mb: unquote(attrs["fly_memory_gb"] * 1024),
            gpu_kind: unquote(attrs["fly_gpu_kind"]),
            token: System.fetch_env!("LB_FLY_API_TOKEN"),
            env: %{"LIVEBOOK_COOKIE" => Node.get_cookie()}}}
      )
    end
  end
end
