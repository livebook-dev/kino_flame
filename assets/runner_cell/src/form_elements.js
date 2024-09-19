import React from "react";
import {
  RiCloseLine,
  RiArrowDownSLine,
  RiQuestionLine,
} from "@remixicon/react";
import classNames from "classnames";

export function SelectField({
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

export function MultiSelectField({
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

export function FieldWrapper({ children }) {
  return <div className="flex items-center gap-1.5">{children}</div>;
}

export function InlineLabel({ label }) {
  return (
    <label className="block text-sm font-medium uppercase text-gray-600">
      {label}
    </label>
  );
}

export function TextField({
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

export function Switch({ label = null, checked, help = null, ...props }) {
  return (
    <div className="flex flex-col">
      {label && (
        <span className="color-gray-800 mb-0.5 block text-sm font-medium flex items-center gap-1">
          {label}
          {help && (
            <span className="cursor-pointer tooltip right" data-tooltip={help}>
              <RiQuestionLine size={14} />
            </span>
          )}
        </span>
      )}
      <div className="grow flex items-center">
        <label className="relative inline-block h-7 w-14 select-none">
          <input
            type="checkbox"
            className="peer absolute block h-7 w-7 cursor-pointer appearance-none rounded-full border-[5px] border-gray-100 bg-gray-400 outline-none transition-all duration-300 checked:translate-x-full checked:transform checked:border-blue-600 checked:bg-white"
            checked={checked}
            {...props}
          />
          <div className="block h-full w-full cursor-pointer rounded-full bg-gray-100 transition-all duration-300 peer-checked:bg-blue-600" />
        </label>
      </div>
    </div>
  );
}
