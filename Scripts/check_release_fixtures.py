"""Verify the actual Release app excludes developer fixture data and adapters."""
from pathlib import Path
import re
import sys

executable = Path(sys.argv[1])
app = executable.parent
if (app / "DeveloperFixtures").exists() or list(app.rglob("mytv-developer-catalog.json")):
    raise SystemExit("Debug fixture catalog found in Release app")
if re.search(rb"\$s4myTV[0-9]+DeveloperStubRepositoryC", executable.read_bytes()):
    raise SystemExit("Debug fixture adapter found in Release executable")
print("Release excludes shared fixture catalogs and developer adapters.")
