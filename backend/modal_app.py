import modal
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent

# Image for the main FastAPI controller
controller_image = (
    modal.Image.debian_slim(python_version="3.11")
    .pip_install(
        "fastapi",
        "uvicorn",
        "python-jose[cryptography]",
        "google-auth",
        "google-auth-oauthlib",
        "requests",
        "pydantic",
        "httpx",
    )
    .add_local_dir(".", remote_path="/app", ignore=[
        "frontend/node_modules",
        "frontend/.vite",
        "__pycache__",
        "*.pyc",
        ".env",
        "venv",
    ])
)

# Image for per-user sandboxes (has Claude Code CLI + sandbox server)
sandbox_image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("nodejs", "npm")
    .run_commands("npm install -g @anthropic-ai/claude-code")
    .pip_install(
        "claude-agent-sdk",
    )
    .add_local_dir(BACKEND_DIR, remote_path="/app", ignore=[
        "frontend",
        "__pycache__",
        "*.pyc",
        ".env",
        "venv",
    ])
)

app = modal.App(name="monios-api")

# Volume to store sandbox server code (shared across all sandboxes)
code_volume = modal.Volume.from_name("monios-sandbox-code", create_if_missing=True)


monios_secrets = modal.Secret.from_name("monios-secrets")


@app.function(
    image=controller_image,
    secrets=[monios_secrets],
    volumes={"/code": code_volume},
)
@modal.asgi_app()
def fastapi_app():
    import sys
    sys.path.insert(0, "/app")

    # Write sandbox_server.py to the shared code volume (always refresh)
    import shutil
    from pathlib import Path
    code_path = Path("/code/sandbox_server.py")
    shutil.copy("/app/sandbox_server.py", code_path)
    code_volume.commit()
    print("[modal_app] Refreshed sandbox_server.py in code volume")

    # Initialize sandbox manager with app, image, secrets, and code volume
    import sandbox_manager
    sandbox_manager.init(
        app,
        sandbox_image,
        secrets=[monios_secrets],
        code_volume=code_volume,
    )

    from main import app as fastapi_application
    return fastapi_application
