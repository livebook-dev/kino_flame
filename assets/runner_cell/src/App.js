import React, { useEffect, useRef, useState } from "react";
import {
  RiQuestionnaireLine,
  RiArrowDownSLine,
  RiCloseLine,
} from "@remixicon/react";
import classNames from "classnames";

const FLY_CPU_KIND_OPTIONS = ["shared", "performance"].map((kind) => ({
  value: kind,
  label: kind,
}));

const FLY_GPU_KIND_OPTIONS = [{ value: "", label: "None" }].concat(
  ["a10", "a100-pcie-40gb", "a100-sxm4-80gb", "l40s"].map((kind) => ({
    value: kind,
    label: kind,
  })),
);

export default function App({ ctx, payload }) {
  const [fields, setFields] = useState(payload.fields);
  const [allEnvs, setAllEnvs] = useState(payload.all_envs);
  const [showHelpBox, setShowHelpBox] = useState(false);
  const warning_type = payload.warning_type;

  useEffect(() => {
    ctx.handleEvent("update", ({ fields }) => {
      setFields((currentFields) => ({ ...currentFields, ...fields }));
    });

    ctx.handleEvent("set_all_envs", ({ all_envs }) => {
      setAllEnvs(all_envs);
    });
  }, []);

  function pushUpdate(field, value) {
    ctx.pushEvent("update_field", { field, value });
  }

  function handleChange(event, push = true) {
    const field = event.target.name;

    const value =
      event.target.type === "checkbox"
        ? event.target.checked
        : event.target.value;

    handleFieldChange(field, value, push);
  }

  function handleBlur(event) {
    const field = event.target.name;

    pushUpdate(field, fields[field]);
  }

  function handleFieldChange(field, value, push = true) {
    setFields({ ...fields, [field]: value });

    if (push) {
      pushUpdate(field, value);
    }
  }

  return (
    <div className="flex flex-col gap-4 font-sans">
      {warning_type === "no_fly" && (
        <MessageBox variant="warning">
          Using FLAME Fly backend only works when running within the Fly
          infrastructure. To use it, either use the Livebook Fly runtime or
          deploy your Livebook as a Fly app.
        </MessageBox>
      )}
      {warning_type === "no_fly_token" && (
        <MessageBox variant="warning">
          FLAME Fly backend expects the FLY_API_TOKEN environment variable to be
          set, but none was found. If you are running Livebook as a Fly app, you
          can set it as a secret:
          <pre className="mt-2 p-4 whitespace-pre-wrap">
            <code>fly secrets set FLY_API_TOKEN="$(fly auth token)"</code>
          </pre>
        </MessageBox>
      )}
      <div className="rounded-lg border border-gray-300 bg-[#fefefe]">
        <Header>
          <FieldWrapper>
            <InlineLabel label="Start FLAME" />
            <TextField
              name="name"
              value={fields.name}
              onChange={handleChange}
            />
          </FieldWrapper>
          <FieldWrapper>
            <InlineLabel label="Using" />
            <SelectField
              name="backend"
              value="fly"
              options={[{ value: "fly", label: "Fly" }]}
              disabled
            />
          </FieldWrapper>
          <div className="grow"></div>
          <div className="flex items-center">
            <IconButton onClick={(_event) => setShowHelpBox(!showHelpBox)}>
              <RiQuestionnaireLine size={20} />
            </IconButton>
          </div>
        </Header>
        {showHelpBox && <HelpBox />}
        <div className="flex flex-wrap gap-2 p-4">
          <div className="w-36">
            <TextField
              type="number"
              name="min"
              label="Min runners"
              value={fields.min}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
              min="0"
              required
            />
          </div>
          <div className="w-36">
            <TextField
              type="number"
              name="max"
              label="Max runners"
              value={fields.max}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
              min="1"
              required
            />
          </div>
          <div className="w-36">
            <TextField
              type="number"
              name="max_concurrency"
              label="Max concurrency"
              value={fields.max_concurrency}
              onChange={(event) => handleChange(event, false)}
              onBlur={handleBlur}
              min="1"
              required
            />
          </div>
        </div>
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
              onChange={(event) => handleChange(event, false)}
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
              onChange={(event) => handleChange(event, false)}
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
              onChange={(event) => handleChange(event, false)}
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
    </div>
  );
}

function HelpBox(_props) {
  return (
    <div className="flex flex-col gap-5 border-b border-gray-200 p-4 text-sm text-gray-700">
      <p>
        This smart cell starts a{" "}
        <a
          href="https://github.com/phoenixframework/flame"
          target="_blank"
          className="border-b border-gray-900 font-medium text-gray-900 no-underline hover:border-none"
        >
          FLAME
        </a>
        pool that delegates computation to a separate machines. To learn more
        about the configuration details, refer to{" "}
        <a
          href="https://hexdocs.pm/flame"
          target="_blank"
          className="border-b border-gray-900 font-medium text-gray-900 no-underline hover:border-none"
        >
          the documentation
        </a>
        .
      </p>
      <p>
        Once a pool is started, you can execute code on a separate machine as
        follows:
        <pre className="mt-2 p-4 bg-[#282c34] rounded-lg whitespace-pre-wrap">
          <code className="text-[#c8ccd4]">
            <span className="text-[#56b6c2]">FLAME</span>
            <span className="text-[#d19a66]">.</span>
            <span className="text-[#61afef]">call</span>(
            <span className="text-[#61afef]">:runner</span>,{" "}
            <span className="text-[#c678dd]">fn</span>{" "}
            <span className="text-[#d19a66]">{"->"}</span>
            {"\n  ...\n"}
            <span className="text-[#c678dd]">end</span>)
          </code>
        </pre>
      </p>
    </div>
  );
}

function MessageBox({ variant = "neutral", children }) {
  return (
    <div
      className={classNames([
        "rounded-lg border p-4 text-sm",
        {
          neutral: "border-gray-300 text-gray-700",
          warning: "color-gray-900 border-yellow-600 bg-yellow-100",
        }[variant],
      ])}
    >
      {children}
    </div>
  );
}

function Header({ children }) {
  return (
    <div className="align-stretch flex flex-wrap justify-start gap-4 rounded-t-lg border-b border-b-gray-200 bg-blue-100 px-4 py-2">
      {children}
    </div>
  );
}

function IconButton({ children, ...props }) {
  return (
    <button
      {...props}
      className="align-center flex cursor-pointer items-center rounded-full p-1 leading-none text-gray-500 hover:text-gray-900 focus:bg-gray-300/25 focus:outline-none disabled:cursor-default disabled:text-gray-300"
    >
      {children}
    </button>
  );
}

function SelectField({
  label = null,
  value,
  className,
  options = [],
  optionGroups = [],
  ...props
}) {
  function renderOptions(options) {
    return options.map((option) => (
      <option key={option.value || ""} value={option.value || ""}>
        {option.label}
      </option>
    ));
  }

  return (
    <div className="flex flex-col">
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div className="relative block">
        <select
          {...props}
          value={value}
          className={classNames([
            "w-full appearance-none rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 pr-7 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        >
          {renderOptions(options)}
          {optionGroups.map(({ label, options }) => (
            <optgroup key={label} label={label}>
              {renderOptions(options)}
            </optgroup>
          ))}
        </select>
        <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500">
          <RiArrowDownSLine size={16} />
        </div>
      </div>
    </div>
  );
}

function MultiSelectField({
  label = null,
  value,
  className,
  options = [],
  onChange,
  ...props
}) {
  const availableOptions = options.filter(
    (option) => !value.includes(option.value),
  );

  function labelForValue(value) {
    const option = options.find((option) => option.value === value);

    if (option) {
      return option.label;
    } else {
      return value;
    }
  }

  function handleSelectChange(event) {
    const subvalue = event.target.value;
    const newValue = value.concat([subvalue]).sort();
    onChange && onChange(newValue);
  }

  function handleDelete(subvalue) {
    const newValue = value.filter(
      (otherSubvalue) => otherSubvalue !== subvalue,
    );
    onChange && onChange(newValue);
  }

  return (
    <div className="flex flex-col min-w-36">
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "relative w-full min-h-[38px] flex rounded-lg border border-gray-200 bg-gray-50 px-3 py-1.5 pr-0 text-sm text-gray-600 placeholder-gray-400",
          className,
        ])}
      >
        <div className="flex flex-wrap gap-1">
          {value.map((value) => (
            <div
              key={value}
              className="py-0.5 px-2 flex gap-1 items-center rounded-lg bg-gray-200"
            >
              <span>{labelForValue(value)}</span>
              <button
                className="rounded-lg hover:bg-gray-300"
                onClick={() => handleDelete(value)}
              >
                <RiCloseLine size={12} />
              </button>
            </div>
          ))}
        </div>
        <select
          {...props}
          value=""
          onChange={handleSelectChange}
          className="grow min-w-8 w-0 opacity-0 appearance-none focus:outline-none"
        >
          <option value="" disabled></option>
          {availableOptions.map((option) => (
            <option key={option.value || ""} value={option.value || ""}>
              {option.label}
            </option>
          ))}
        </select>
        <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-gray-500">
          <RiArrowDownSLine size={16} />
        </div>
      </div>
    </div>
  );
}

function FieldWrapper({ children }) {
  return <div className="flex items-center gap-1.5">{children}</div>;
}

function InlineLabel({ label }) {
  return (
    <label className="block text-sm font-medium uppercase text-gray-600">
      {label}
    </label>
  );
}

function TextField({
  label = null,
  value,
  type = "text",
  className,
  required = false,
  fullWidth = false,
  inputRef,
  startAdornment,
  ...props
}) {
  return (
    <div
      className={classNames([
        "flex max-w-full flex-col",
        fullWidth ? "w-full" : "w-[20ch]",
      ])}
    >
      {label && (
        <label className="color-gray-800 mb-0.5 block text-sm font-medium">
          {label}
        </label>
      )}
      <div
        className={classNames([
          "flex items-stretch overflow-hidden rounded-lg border bg-gray-50",
          required && value === null ? "border-red-300" : "border-gray-200",
        ])}
      >
        {startAdornment}
        <input
          {...props}
          ref={inputRef}
          type={type}
          value={value === null ? "" : value}
          className={classNames([
            "w-full bg-transparent px-3 py-2 text-sm text-gray-600 placeholder-gray-400 focus:outline-none",
            className,
          ])}
        />
      </div>
    </div>
  );
}
