import React, { useEffect, useState } from "react";
import { RiQuestionnaireLine } from "@remixicon/react";
import classNames from "classnames";
import Fly from "./Fly";
import {
  FieldWrapper,
  InlineLabel,
  SelectField,
  TextField,
} from "./form_elements";
import K8s from "./K8s";

const BACKEND_OPTIONS = [
  { value: "fly", label: "Fly" },
  { value: "k8s", label: "Kubernetes" },
];

export default function App({ ctx, payload }) {
  const [fields, setFields] = useState(payload.fields);
  const [allEnvs, setAllEnvs] = useState(payload.all_envs);
  const [showHelpBox, setShowHelpBox] = useState(false);
  const [missingDep, setMissingDep] = useState(payload.missing_dep);
  const [missingLivebookCookie, setMissingLivebookCookie] = useState(
    payload.missing_livebook_cookie,
  );
  const warnings = payload.warnings;

  useEffect(() => {
    ctx.handleEvent("update", ({ fields }) => {
      setFields((currentFields) => ({ ...currentFields, ...fields }));
    });

    ctx.handleEvent("missing_dep", ({ dep }) => {
      setMissingDep(dep);
    });

    ctx.handleEvent("missing_livebook_cookie", ({ is_missing }) => {
      setMissingLivebookCookie(is_missing);
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
      {fields.backend == "fly" && warnings.no_fly && (
        <MessageBox variant="warning">
          Using FLAME Fly backend only works when running within the Fly
          infrastructure. To use it, either use the Livebook Fly runtime or
          deploy your Livebook as a Fly app.
        </MessageBox>
      )}
      {fields.backend == "fly" && !warnings.no_fly && warnings.no_fly_token && (
        <MessageBox variant="warning">
          FLAME Fly backend expects the FLY_API_TOKEN environment variable to be
          set, but none was found. If you are running Livebook as a Fly app, you
          can set it as a secret:
          <pre className="mt-2 p-4 whitespace-pre-wrap">
            <code>fly secrets set FLY_API_TOKEN="$(fly auth token)"</code>
          </pre>
        </MessageBox>
      )}
      {fields.backend == "k8s" && warnings.no_k8s && (
        <MessageBox variant="warning">
          Using FLAME Kubernetes backend only works when Livebook is running on
          a Kubernetes cluster. To use it, either use the Livebook K8s runtime
          or deploy your Livebook as a{" "}
          <a
            class="text-indigo-500"
            target="_blank"
            href="https://artifacthub.io/packages/helm/livebook/livebook"
          >
            Kubernetes deployment
          </a>
          .
        </MessageBox>
      )}
      {fields.backend == "k8s" && missingDep && (
        <MessageBox variant="warning">
          <p>
            To successfully start the FLAME pool, you need to add the following
            dependency:
          </p>
          <pre>
            <code>{missingDep}</code>
          </pre>
        </MessageBox>
      )}
      {fields.backend == "k8s" && missingLivebookCookie && (
        <MessageBox variant="warning">
          To successfully connect to the runtime, your Pod template must declare
          the following env variable:
          <pre>
            <code>{`\nenv:\n- name: LIVEBOOK_COOKIE\n  value: #{Node.get_cookie()}`}</code>
          </pre>
        </MessageBox>
      )}
      <div
        className={classNames([
          "border border-gray-300 bg-[#fefefe]",
          fields.backend == "k8s" ? "rounded-t-lg" : "rounded-lg",
        ])}
      >
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
              value={fields.backend}
              options={BACKEND_OPTIONS}
              onChange={handleChange}
            />
          </FieldWrapper>
          <div className="grow"></div>
          <div className="flex items-center">
            <IconButton onClick={(_event) => setShowHelpBox(!showHelpBox)}>
              <RiQuestionnaireLine size={20} />
            </IconButton>
          </div>
        </Header>
        {showHelpBox && <HelpBox fields={fields} />}
        {fields.backend == "fly" && (
          <Fly
            fields={fields}
            allEnvs={allEnvs}
            handleBlur={handleBlur}
            handleChange={handleChange}
            handleFieldChange={handleFieldChange}
          />
        )}
        {fields.backend == "k8s" && (
          <K8s
            fields={fields}
            handleBlur={handleBlur}
            handleChange={handleChange}
          />
        )}
      </div>
    </div>
  );
}

function HelpBox({ fields }) {
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
        </a>{" "}
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
        On start, FLAME will package all of your notebook's dependencies and
        automatically synchronize modules defined within Livebook with remote
        nodes. Note that process state and application configuration are not
        automatically carried to remote nodes.
      </p>
      <div>
        <p>
          Once a pool is started, you can execute code on a separate machine as
          follows:
        </p>
        <pre className="mt-2 p-4 bg-[#282c34] rounded-lg whitespace-pre-wrap">
          <code className="text-[#c8ccd4]">
            <span className="text-[#56b6c2]">FLAME</span>
            <span className="text-[#d19a66]">.</span>
            <span className="text-[#61afef]">call</span>(
            <span className="text-[#61afef]">:{fields.name}</span>,{" "}
            <span className="text-[#c678dd]">fn</span>{" "}
            <span className="text-[#d19a66]">{"->"}</span>
            {"\n  ...\n"}
            <span className="text-[#c678dd]">end</span>)
          </code>
        </pre>
      </div>
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
