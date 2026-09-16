import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

PG_USER = os.environ.get("POSTGRES_USER", "postgres")
PG_DB = os.environ.get("POSTGRES_DB", "superstore_dwh")

STEPS = [
    ("00_setup: create schemas", "/sql/00_setup/01_create_schemas.sql"),
    ("10_stg: create sales_raw", "/sql/10_stg/01_create_sales_raw.sql"),
    ("10_stg: load sales_raw", "/sql/10_stg/02_load_sales_raw.sql"),
    ("10_stg: verify load", "/sql/10_stg/03_verify_load.sql"),
]


def run(cmd, **kwargs):
    return subprocess.run(cmd, **kwargs)


def main():
    os.chdir(ROOT)

    if shutil.which("docker") is None:
        print("ERROR: docker not found. Install Docker Desktop and try again.", file=sys.stderr)
        return 1
    if run(["docker", "info"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode != 0:
        print("ERROR: Docker daemon is not running. Start Docker Desktop and try again.", file=sys.stderr)
        return 1

    print("== Starting database (waits until healthy) ==")
    if run(["docker", "compose", "up", "-d", "--wait"]).returncode != 0:
        return 1

    for name, container_path in STEPS:
        print(f"== {name} ==")
        result = run([
            "docker", "compose", "exec", "-T", "db",
            "psql", "-U", PG_USER, "-d", PG_DB,
            "-v", "ON_ERROR_STOP=1", "-f", container_path,
        ])
        if result.returncode != 0:
            print(f"FAILED at {container_path}", file=sys.stderr)
            return 1

    print("== Staging run complete ==")
    return 0


if __name__ == "__main__":
    sys.exit(main())
