import React from "react";
import { MultiSelectField, SelectField, TextField } from "./form_elements";
import Pool from "./Pool";

const FLY_CPU_KIND_OPTIONS = ["shared", "performance"].map((kind) => ({
  value: kind,
  label: kind,
}));

const FLY_GPU_KIND_OPTIONS = [{ value: "", label: "None" }].concat(
  ["a10", "a100-pcie-40gb", "a100-sxm4-80gb", "l40s"].map((kind) => ({
    value: kind,
    label: kind,
  }))
);

export default function Fly({
  fields,
  allEnvs,
  handleBlur,
  handleChange,
  handleFieldChange,
}) {
  return (
    <div>
      <Pool
        fields={fields}
        handleChange={handleChange}
        handleBlur={handleBlur}
      />
      <div className="w-full border-t border-gray-200" />
      <div className="flex flex-wrap gap-2 p-4">
        <SelectField
          name="fly_cpu_kind"
          label="CPU kind"
          value={fields.fly_cpu_kind}
          onChange={handleChange}
          options={FLY_CPU_KIND_OPTIONS}
        />
        <div className="w-36">
          <TextField
            type="number"
            name="fly_cpus"
            label="CPUs"
            value={fields.fly_cpus}
            onChange={handleChange}
            onBlur={handleBlur}
            min="1"
            required
          />
        </div>
        <div className="w-36">
          <TextField
            type="number"
            name="fly_memory_gb"
            label="Memory (GB)"
            value={fields.fly_memory_gb}
            onChange={handleChange}
            onBlur={handleBlur}
            min="1"
            required
          />
        </div>
        <SelectField
          name="fly_gpu_kind"
          label="GPU kind"
          value={fields.fly_gpu_kind || ""}
          onChange={handleChange}
          options={FLY_GPU_KIND_OPTIONS}
        />
        <div className="w-36">
          <TextField
            type="number"
            name="fly_gpus"
            label="GPUs"
            value={fields.fly_gpus}
            onChange={handleChange}
            onBlur={handleBlur}
            min="1"
          />
        </div>
      </div>
      <div className="w-full border-t border-gray-200" />
      <div className="flex flex-wrap gap-2 p-4">
        <MultiSelectField
          name="fly_envs"
          label="Env vars"
          value={fields.fly_envs}
          onChange={(value) => handleFieldChange("fly_envs", value)}
          options={allEnvs.map((env) => ({ label: env, value: env }))}
        />
      </div>
    </div>
  );
}
