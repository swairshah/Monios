from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime, timezone
import random
from auth.middleware import get_current_user
from auth.jwt import TokenData

from claude_agent_sdk import query, ClaudeAgentOptions, AssistantMessage, TextBlock, ResultMessage

router = APIRouter(prefix="/api", tags=["chat"])


class ChatMessage(BaseModel):
    content: str


class ChatResponse(BaseModel):
    id: str
    content: str
    timestamp: str
    user_email: str


@router.post("/chat", response_model=ChatResponse)
async def chat(
    message: ChatMessage,
    user: TokenData = Depends(get_current_user)
):
    """
    Protected chat endpoint using Claude Agent SDK.

    Requires Claude Code CLI to be installed:
    npm install -g @anthropic-ai/claude-code
    """
    try:
        response_text = ""

        # Use Claude Agent SDK query
        options = ClaudeAgentOptions(
            system_prompt="You are a helpful assistant in a terminal-aesthetic chat app called Monios. Keep responses concise and use a casual, friendly tone.",
            allowed_tools=[],  # No tools for simple chat
            max_turns=1
        )

        async for msg in query(prompt=message.content, options=options):
            if isinstance(msg, AssistantMessage):
                for block in msg.content:
                    if isinstance(block, TextBlock):
                        response_text += block.text

        if not response_text:
            response_text = "I couldn't generate a response. Please try again."

        return ChatResponse(
            id=f"msg_{random.randint(100000, 999999)}",
            content=response_text,
            timestamp=datetime.now(timezone.utc).isoformat(),
            user_email=user.email,
        )

    except Exception as e:
        # Log the error and return a friendly message
        print(f"Claude SDK error: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to get response: {str(e)}"
        )


@router.get("/chat/history")
async def get_chat_history(
    user: TokenData = Depends(get_current_user),
    limit: int = 50,
    offset: int = 0,
):
    """Get chat history for the authenticated user."""
    return {
        "messages": [],
        "total": 0,
        "limit": limit,
        "offset": offset,
        "user_id": user.user_id,
    }


@router.get("/session")
async def get_session(user: TokenData = Depends(get_current_user)):
    """Get current session info."""
    return {
        "user_id": user.user_id,
        "email": user.email,
        "authenticated": True,
    }
