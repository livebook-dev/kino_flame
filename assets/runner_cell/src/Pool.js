import React from "react";
import { SelectField, TextField } from "./form_elements";

const Pool = ({ fields, handleChange, handleBlur }) => (
  <div className="flex flex-wrap gap-2 p-4">
    <div className="w-36">
      <TextField
        type="number"
        name="min"
        label="Min instances"
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
        label="Max instances"
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
);

export default Pool;
