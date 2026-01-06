"""Shared session management for Claude SDK clients."""

from claude_agent_sdk import ClaudeSDKClient, ClaudeAgentOptions, AssistantMessage, TextBlock

# Shared session store for all users (web + iOS)
_sessions: dict[str, ClaudeSDKClient] = {}

SYSTEM_PROMPT = "You are a helpful assistant in a terminal-aesthetic chat app called Monios. Keep responses concise and friendly."


async def get_or_create_client(user_id: str) -> ClaudeSDKClient:
    """Get existing client or create new one for user."""
    if user_id not in _sessions:
        options = ClaudeAgentOptions(
            system_prompt=SYSTEM_PROMPT,
            allowed_tools=[],
            max_turns=10  # Allow multiple turns for tool use + response
        )
        client = ClaudeSDKClient(options=options)
        await client.connect()
        _sessions[user_id] = client
    return _sessions[user_id]


async def clear_session(user_id: str) -> bool:
    """Clear session for a user. Returns True if session existed."""
    if user_id in _sessions:
        try:
            await _sessions[user_id].disconnect()
        except:
            pass
        del _sessions[user_id]
        return True
    return False


async def get_response(user_id: str, message: str) -> str:
    """Send message and get response for a user."""
    client = await get_or_create_client(user_id)
    await client.query(prompt=message)

    response_text = ""
    async for msg in client.receive_response():
        if isinstance(msg, AssistantMessage):
            for block in msg.content:
                if isinstance(block, TextBlock):
                    response_text += block.text

    return response_text
