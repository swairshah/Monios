import modal

# Build image with Node.js + Claude Code CLI + Python dependencies
# NOTE: add_local_dir must be LAST - no build steps allowed after it
# Build frontend locally first: cd frontend && bun install && bun run build
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("nodejs", "npm")
    # Install Claude Code CLI
    .run_commands("npm install -g @anthropic-ai/claude-code")
    # Install Python deps BEFORE copying local files
    .pip_install(
        "fastapi",
        "python-jose[cryptography]",
        "google-auth",
        "google-auth-oauthlib",
        "requests",
        "pydantic",
        "claude-agent-sdk",
    )
    # Copy backend code LAST (includes pre-built frontend/dist)
    .add_local_dir(".", remote_path="/app", ignore=[
        "frontend/node_modules",
        "frontend/.vite",
        "__pycache__",
        "*.pyc",
        ".env",
        "venv",
    ])
)

app = modal.App(name="monios-api", image=image)


@app.function(
    secrets=[modal.Secret.from_name("monios-secrets")],
    env={"IS_SANDBOX": "1"},
)
@modal.asgi_app()
def fastapi_app():
    import sys
    sys.path.insert(0, "/app")
    from main import app as fastapi_application
    return fastapi_application
