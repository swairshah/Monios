"""Shared session management for Claude SDK clients."""

import json
from pathlib import Path

from claude_agent_sdk import (
    ClaudeSDKClient,
    ClaudeAgentOptions,
    AssistantMessage,
    TextBlock,
    SystemMessage,
)

# Shared session store for all users (web + iOS)
_sessions: dict[str, ClaudeSDKClient] = {}

# Persist session_ids to survive restarts
_SESSION_FILE = Path(__file__).parent / ".session_ids.json"
_session_ids: dict[str, str] = {}  # user_id -> session_id


def _load_session_ids():
    """Load persisted session_ids from disk."""
    global _session_ids
    if _SESSION_FILE.exists():
        try:
            _session_ids = json.loads(_SESSION_FILE.read_text())
        except (json.JSONDecodeError, IOError):
            _session_ids = {}


def _save_session_ids():
    """Save session_ids to disk."""
    try:
        _SESSION_FILE.write_text(json.dumps(_session_ids, indent=2))
    except IOError:
        pass


# Load on module import
_load_session_ids()

SYSTEM_PROMPT = "You are a helpful assistant in a terminal-aesthetic chat app called Monios. Keep responses concise and friendly."


async def get_or_create_client(user_id: str) -> ClaudeSDKClient:
    """Get existing client or create new one for user."""
    if user_id not in _sessions:
        options = ClaudeAgentOptions(
            system_prompt=SYSTEM_PROMPT,
            allowed_tools=[],
            permission_mode="bypassPermissions",
            max_turns=10,  # Allow multiple turns for tool use + response
            cwd="../workspace"
        )
        client = ClaudeSDKClient(options=options)
        await client.connect()
        _sessions[user_id] = client
    return _sessions[user_id]


async def clear_session(user_id: str) -> bool:
    """Clear session for a user. Returns True if session existed."""
    existed = False
    if user_id in _sessions:
        try:
            await _sessions[user_id].disconnect()
        except:
            pass
        del _sessions[user_id]
        existed = True
    if user_id in _session_ids:
        del _session_ids[user_id]
        _save_session_ids()
        existed = True
    return existed

async def get_response(message: str, user_id: str, session_id: str | None = None) -> (str, str):
    """Send message and get response for a user."""
    client = await get_or_create_client(user_id)

    # Use provided session_id, or fall back to persisted one
    effective_session_id = session_id or _session_ids.get(user_id)

    print(f"user_id: {user_id}")
    print(f"message: {message}")
    print(f"effective_session_id: {effective_session_id}")
    if effective_session_id:
        await client.query(prompt=message, session_id=effective_session_id)
    else:
        await client.query(prompt=message)

    response_text = ""
    new_session_id = None
    async for msg in client.receive_response():
        if isinstance(msg, SystemMessage):
            data = msg.data
            new_session_id = data.get("session_id", None)
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    response_text += block.text

    # Persist the session_id for this user
    if new_session_id:
        _session_ids[user_id] = new_session_id
        _save_session_ids()

    return response_text, new_session_id
