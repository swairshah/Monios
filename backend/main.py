from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from pydantic import BaseModel
import uvicorn
import os
from config import get_settings
from routes import auth_router, chat_router
from sessions import get_response, clear_session

app = FastAPI(
    title="Monios API",
    description="Backend API for Monios chat application",
    version="1.0.0",
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router)
app.include_router(chat_router)


# Public chat endpoint for web UI (no auth required)
class WebChatRequest(BaseModel):
    message: str
    user_id: str = "guest"


@app.post("/chat")
async def web_chat(request: WebChatRequest):
    """Public chat endpoint for web UI."""
    try:
        response_text = await get_response(request.user_id, request.message)

        if not response_text:
            return {"content": "No response generated (empty result)", "user_id": request.user_id}

        return {"content": response_text, "user_id": request.user_id}

    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        print(f"Chat error: {error_details}")
        await clear_session(request.user_id)
        return {"content": f"Error: {type(e).__name__}: {str(e)}", "user_id": request.user_id}


@app.post("/chat/clear")
async def clear_chat(request: WebChatRequest):
    """Clear chat history for a user."""
    await clear_session(request.user_id)
    return {"status": "cleared", "user_id": request.user_id}


@app.get("/health")
async def health():
    return {"status": "healthy"}


# Serve static frontend files
FRONTEND_DIR = os.path.join(os.path.dirname(__file__), "frontend", "dist")

if os.path.exists(FRONTEND_DIR):
    app.mount("/assets", StaticFiles(directory=os.path.join(FRONTEND_DIR, "assets")), name="assets")

    @app.get("/")
    async def serve_frontend():
        return FileResponse(os.path.join(FRONTEND_DIR, "index.html"))
else:
    @app.get("/")
    async def root():
        return {
            "name": "Monios API",
            "version": "1.0.0",
            "status": "running",
            "note": "Frontend not built. Run 'cd frontend && bun install && bun run build'"
        }


if __name__ == "__main__":
    settings = get_settings()
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=True,
    )
