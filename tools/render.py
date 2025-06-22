#!/usr/bin/env python3
"""
render.py  –  ComposeForge catalog renderer
Usage:
    python3 tools/render.py nextcloud \
           --out-dir /tmp/pkg \
           --port 8081
"""
import argparse, pathlib, secrets, shutil, os, yaml, jinja2

ROOT = pathlib.Path(__file__).parent.parent   # repo root

def render(app, out_dir, port):
    tpl_dir = ROOT / "templates" / app
    out_dir = pathlib.Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    # ----- copy compose template verbatim -------------------
    compose_in = tpl_dir / "docker-compose.yml"
    shutil.copy2(compose_in, out_dir / "docker-compose.yml")

    # ----- build .env ---------------------------------------
    env_sample = ROOT / ".env.sample"
    env_out    = out_dir / ".env"
    env_vars   = {}
    for line in env_sample.read_text().splitlines():
        if "=" in line and not line.startswith("#"):
            k, v = line.split("=", 1)
            env_vars[k] = v

    # inject user choices & secrets
    env_vars["NEXTCLOUD_PORT"]        = str(port)
    env_vars["NEXTCLOUD_DB_ROOT_PASS"] = secrets.token_urlsafe(16)
    env_vars["NEXTCLOUD_DB_PASS"]      = secrets.token_urlsafe(16)

    env_out.write_text("\n".join(f"{k}={v}" for k, v in env_vars.items()))
    print(f"Rendered to {out_dir}")

if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("app", choices=["nextcloud"])
    p.add_argument("--out-dir", default="render-out")
    p.add_argument("--port", type=int, default=8081)
    args = p.parse_args()
    render(args.app, args.out_dir, args.port)

