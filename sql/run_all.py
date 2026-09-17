#!/usr/bin/env python3
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def load_env_file(path):
    values = {}
    if not path.exists():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


ENV_FILE = load_env_file(ROOT / ".env")


def setting(name, default):
    # same precedence as Docker Compose: shell environment, then .env, then default
    return os.environ.get(name) or ENV_FILE.get(name) or default


PG_USER = setting("POSTGRES_USER", "postgres")
PG_DB = setting("POSTGRES_DB", "superstore_dwh")

# the cleansed views read stg.sales_raw, so they are dropped before staging is rebuilt
STEPS = [
    ("00_setup: create schemas", "/sql/00_setup/01_create_schemas.sql"),
    ("20_cleansed: drop views", "/sql/20_cleansed/01_drop_views.sql"),
    ("10_stg: create sales_raw", "/sql/10_stg/01_create_sales_raw.sql"),
    ("10_stg: load sales_raw", "/sql/10_stg/02_load_sales_raw.sql"),
    ("10_stg: verify load", "/sql/10_stg/03_verify_load.sql"),
    ("20_cleansed: create sales_checked", "/sql/20_cleansed/02_create_sales_checked.sql"),
    ("20_cleansed: create sales", "/sql/20_cleansed/03_create_sales.sql"),
    ("20_cleansed: create dq_rejects", "/sql/20_cleansed/04_create_dq_rejects.sql"),
    ("20_cleansed: verify cleansed", "/sql/20_cleansed/05_verify_cleansed.sql"),
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

    print("== Pipeline run complete ==")
    return 0


if __name__ == "__main__":
    sys.exit(main())
