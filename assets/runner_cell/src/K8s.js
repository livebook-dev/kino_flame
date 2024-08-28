import React from "react";
import Pool from "./Pool";

export default function K8s({ fields, handleChange, handleBlur }) {
  return (
    <div>
      <Pool
        fields={fields}
        handleChange={handleChange}
        handleBlur={handleBlur}
      />
    </div>
  );
}
