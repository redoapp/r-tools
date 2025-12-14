import { getInput, setFailed } from "@actions/core";
import { summary } from "@actions/core";
import { context } from "@actions/github";

(async () => {
  switch (context.eventName) {
    case "workflow_dispatch":
      await writeWorkflowDispatchInputs();
      break;
  }
})().catch((error) => {
  setFailed(error instanceof Error ? error.message : String(error));
});

async function writeWorkflowDispatchInputs() {
  const inputs = context.payload.inputs ?? {};

  for (const [key, value] of Object.entries(inputs)) {
    console.error(`${key}: ${value}`);
  }

  const summary_ = getInput("summary", { required: true });
  if (summary_ === "true") {
    summary.addHeading("Workflow Dispatch", 2);
    summary.addEOL();
    for (const [key, value] of Object.entries(inputs)) {
      summary.addEOL();
      summary.addRaw(`**${key}**: ${value}`, true);
    }
    await summary.write();
  }
}
