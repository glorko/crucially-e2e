#!/usr/bin/env python3
"""Download Maestro docs pages as markdown files."""
import urllib.request
import os
import re
import html
import time

DOCS_DIR = os.path.join(os.path.dirname(__file__), "maestro")
os.makedirs(DOCS_DIR, exist_ok=True)

PAGES = {
    # Wait / sync - critical for our issue
    "wait-commands.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/wait-commands",
    "extendedwaituntil.md": "https://docs.maestro.dev/reference/commands-available/extendedwaituntil",
    "waitforanimationtoend.md": "https://docs.maestro.dev/reference/commands-available/waitforanimationtoend",
    "retry.md": "https://docs.maestro.dev/reference/commands-available/retry",
    # Selectors
    "selectors-guide.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/how-to-use-selectors",
    "core-selectors.md": "https://docs.maestro.dev/reference/selectors/core-selectors",
    "element-traits.md": "https://docs.maestro.dev/reference/selectors/element-traits",
    "state-selectors.md": "https://docs.maestro.dev/reference/selectors/state-selectors",
    # Commands
    "assertvisible.md": "https://docs.maestro.dev/reference/commands-available/assertvisible",
    "assertnotvisible.md": "https://docs.maestro.dev/reference/commands-available/assertnotvisible",
    "launchapp.md": "https://docs.maestro.dev/reference/commands-available/launchapp",
    "tapon.md": "https://docs.maestro.dev/reference/commands-available/tapon",
    "inputtext.md": "https://docs.maestro.dev/reference/commands-available/inputtext",
    "scrolluntilvisible.md": "https://docs.maestro.dev/reference/commands-available/scrolluntilvisible",
    "scroll.md": "https://docs.maestro.dev/reference/commands-available/scroll",
    "runflow.md": "https://docs.maestro.dev/reference/commands-available/runflow",
    "runscript.md": "https://docs.maestro.dev/reference/commands-available/runscript",
    "evalscript.md": "https://docs.maestro.dev/reference/commands-available/evalscript",
    "presskey.md": "https://docs.maestro.dev/reference/commands-available/presskey",
    "stopapp.md": "https://docs.maestro.dev/reference/commands-available/stopapp",
    "swipe.md": "https://docs.maestro.dev/reference/commands-available/swipe",
    # Flow control
    "conditions.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/conditions",
    "loops.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/loops",
    "nested-flows.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/nested-flows",
    "parameters-and-constants.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/parameters-and-constants",
    "detect-maestro.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/detect-maestro",
    "hooks.md": "https://docs.maestro.dev/maestro-flows/flow-control-and-logic/hooks",
    # JavaScript
    "javascript-overview.md": "https://docs.maestro.dev/maestro-flows/javascript/javascript-overview",
    "make-http-requests.md": "https://docs.maestro.dev/maestro-flows/javascript/make-http-requests",
    "manage-data-and-states.md": "https://docs.maestro.dev/maestro-flows/javascript/manage-data-and-states",
    # Workspace / config
    "project-configuration.md": "https://docs.maestro.dev/maestro-flows/workspace-management/project-configuration",
    "workspace-configuration.md": "https://docs.maestro.dev/reference/workspace-configuration",
    "sequential-execution.md": "https://docs.maestro.dev/maestro-flows/workspace-management/sequential-execution",
    # CLI
    "cli-commands.md": "https://docs.maestro.dev/maestro-cli/maestro-cli-commands-and-options",
}

headers = {"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}

ok, fail = 0, 0
for filename, url in PAGES.items():
    path = os.path.join(DOCS_DIR, filename)
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as resp:
            raw = resp.read().decode("utf-8", errors="replace")
        with open(path, "w") as f:
            f.write(f"<!-- source: {url} -->\n\n")
            f.write(raw)
        ok += 1
        print(f"OK  {filename} ({len(raw)} bytes)")
    except Exception as e:
        fail += 1
        print(f"FAIL {filename}: {e}")
    time.sleep(0.3)

print(f"\nDone: {ok} ok, {fail} failed")
