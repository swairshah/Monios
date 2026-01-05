import modal

# Build image with Node.js + Claude Code CLI + Python dependencies
image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("nodejs", "npm")
    .run_commands("npm install -g @anthropic-ai/claude-code")
    .pip_install(
        "fastapi",
        "python-jose[cryptography]",
        "google-auth",
        "google-auth-oauthlib",
        "requests",
        "pydantic",
        "pydantic-settings",
        "claude-agent-sdk",
    )
    .add_local_dir(".", remote_path="/app")
)

app = modal.App(name="monios-api", image=image)


@app.function(
    secrets=[modal.Secret.from_name("monios-secrets")],
)
@modal.asgi_app()
def fastapi_app():
    import sys
    sys.path.insert(0, "/app")
    from main import app as fastapi_application
    return fastapi_application
