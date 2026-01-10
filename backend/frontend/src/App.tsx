import { useState, useEffect, useRef } from "react";
import { useAuth } from "./AuthContext";

interface Message {
  id: string;
  type: "user" | "assistant" | "system" | "tool";
  content: string;
  tool?: ToolEvent;
}

interface ToolEvent {
  type: "tool_use" | "tool_result";
  name?: string;
  input?: unknown;
  tool_use_id?: string;
  content?: unknown;
  is_error?: boolean;
}

function getInitialTheme(): boolean {
  const saved = localStorage.getItem("monios-theme");
  if (saved !== null) {
    return saved === "dark";
  }
  return window.matchMedia("(prefers-color-scheme: dark)").matches;
}

function generateId(): string {
  return Math.random().toString(36).substring(2, 9);
}

function getInitialGuestId(): string {
  return localStorage.getItem("monios-guest-user") || "guest";
}

export default function App() {
  const auth = useAuth();
  const [dark, setDark] = useState(getInitialTheme);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [guestId, setGuestId] = useState(getInitialGuestId);
  const [editingUser, setEditingUser] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const userInputRef = useRef<HTMLInputElement>(null);

  // Get current user identifier (email for auth, guestId for guests)
  const userId = auth.isAuthenticated ? auth.user?.email || "user" : guestId;

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");
  }, [dark]);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const toggleTheme = () => {
    const newDark = !dark;
    setDark(newDark);
    localStorage.setItem("monios-theme", newDark ? "dark" : "light");
  };

  const clearChat = async () => {
    setMessages([]);
    setError(null);
    try {
      if (auth.isAuthenticated) {
        // Use authenticated endpoint
        await fetch("/api/chat/clear", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...auth.getAuthHeaders(),
          },
        });
      } else {
        // Use guest endpoint
        await fetch("/chat/clear", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ user_id: guestId }),
        });
      }
    } catch {
      // Ignore clear errors
    }
  };

  const saveGuestId = (newId: string) => {
    const trimmed = newId.trim() || "guest";
    setGuestId(trimmed);
    localStorage.setItem("monios-guest-user", trimmed);
    setEditingUser(false);
  };

  useEffect(() => {
    if (editingUser && userInputRef.current) {
      userInputRef.current.focus();
      userInputRef.current.select();
    }
  }, [editingUser]);

  const sendMessage = async () => {
    const trimmed = input.trim();
    if (!trimmed || loading) return;

    setInput("");
    setError(null);

    const userMsg: Message = {
      id: generateId(),
      type: "user",
      content: trimmed,
    };
    setMessages(prev => [...prev, userMsg]);
    setLoading(true);

    try {
      let response: Response;

      if (auth.isAuthenticated) {
        // Use authenticated endpoint
        response = await fetch("/api/chat", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...auth.getAuthHeaders(),
          },
          body: JSON.stringify({ content: trimmed }),
        });
      } else {
        // Use guest endpoint
        response = await fetch("/chat", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ message: trimmed, user_id: guestId }),
        });
      }

      if (!response.ok) {
        if (response.status === 401 && auth.isAuthenticated) {
          // Token expired, sign out
          auth.signOut();
          throw new Error("Session expired. Please sign in again.");
        }
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const text = await response.text();
      const lines = text.split("\n");

      const pendingMessages: Message[] = [];

      const appendToolEvents = (events: ToolEvent[]) => {
        for (const event of events) {
          pendingMessages.push({
            id: generateId(),
            type: "tool",
            content: "",
            tool: event,
          });
        }
      };

      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const data = line.slice(6);
          try {
            const parsed = JSON.parse(data);

            if (parsed.type === "assistant" && parsed.message?.content) {
              for (const block of parsed.message.content) {
                if (block.type === "text") {
                  pendingMessages.push({
                    id: generateId(),
                    type: "assistant",
                    content: block.text,
                  });
                } else if (block.type === "tool_use") {
                  appendToolEvents([
                    {
                      type: "tool_use",
                      name: block.name,
                      input: block.input,
                      tool_use_id: block.id,
                    },
                  ]);
                } else if (block.type === "tool_result") {
                  appendToolEvents([
                    {
                      type: "tool_result",
                      tool_use_id: block.tool_use_id,
                      content: block.content,
                      is_error: block.is_error,
                    },
                  ]);
                }
              }
            } else if (parsed.tool_events) {
              appendToolEvents(parsed.tool_events);
            } else if (parsed.type === "result") {
              if (parsed.result) {
                pendingMessages.push({
                  id: generateId(),
                  type: "assistant",
                  content: parsed.result,
                });
              }
            } else if (parsed.content) {
              pendingMessages.push({
                id: generateId(),
                type: "assistant",
                content: parsed.content,
              });
            }
          } catch {
            if (data.trim()) {
              pendingMessages.push({
                id: generateId(),
                type: "assistant",
                content: data,
              });
            }
          }
        }
      }

      // If no SSE data found, try parsing as plain JSON
      if (!text.includes("data: ")) {
        try {
          const json = JSON.parse(text);
          if (json.tool_events) {
            appendToolEvents(json.tool_events);
          }
          if (json.content) {
            pendingMessages.push({
              id: generateId(),
              type: "assistant",
              content: json.content,
            });
          }
        } catch {
          if (text.trim()) {
            pendingMessages.push({
              id: generateId(),
              type: "assistant",
              content: text,
            });
          }
        }
      }

      if (pendingMessages.length) {
        setMessages(prev => [...prev, ...pendingMessages]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to send message");
    } finally {
      setLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const adjustTextareaHeight = () => {
    const textarea = textareaRef.current;
    if (textarea) {
      textarea.style.height = "auto";
      textarea.style.height = Math.min(textarea.scrollHeight, 200) + "px";
    }
  };

  return (
    <div className="app">
      <header>
        <span className="logo">monios</span>
        <div className="header-actions">
          {auth.isAuthenticated ? (
            // Authenticated user display
            <>
              {auth.user?.picture && (
                <img
                  src={auth.user.picture}
                  alt=""
                  className="user-avatar"
                />
              )}
              <span className="user-email">{auth.user?.email}</span>
              <button className="signout-btn" onClick={auth.signOut}>
                sign out
              </button>
            </>
          ) : (
            // Guest mode with login option
            <>
              {editingUser ? (
                <input
                  ref={userInputRef}
                  className="user-input"
                  defaultValue={guestId}
                  onBlur={(e) => saveGuestId(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") saveGuestId(e.currentTarget.value);
                    if (e.key === "Escape") setEditingUser(false);
                  }}
                />
              ) : (
                <button
                  className="user-btn"
                  onClick={() => setEditingUser(true)}
                  title="Click to change guest name"
                >
                  @{guestId}
                </button>
              )}
              <button
                className="google-signin-btn"
                onClick={auth.signInWithGoogle}
                disabled={auth.isLoading}
              >
                {auth.isLoading ? "..." : "sign in"}
              </button>
            </>
          )}
          <button className="clear-btn" onClick={clearChat}>
            clear
          </button>
          <button className="theme-toggle" onClick={toggleTheme}>
            {dark ? "\u2600" : "\u263E"}
          </button>
        </div>
      </header>

      <div className="messages">
        {messages.length === 0 && (
          <div className="message system">
            {auth.isAuthenticated
              ? `signed in as ${auth.user?.email}. send a message to start chatting`
              : "send a message to start chatting (or sign in with Google)"}
          </div>
        )}

        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`message ${msg.type === "tool" ? "assistant" : msg.type}`}
          >
            {msg.type === "tool" && msg.tool ? (
              msg.tool.type === "tool_use" ? (
                <div className="tool-use">
                  <div className="tool-name">tool: {msg.tool.name}</div>
                  <div className="tool-input">
                    {JSON.stringify(msg.tool.input ?? {}, null, 2)}
                  </div>
                </div>
              ) : (
                <div className="tool-result">
                  {JSON.stringify(msg.tool.content ?? "", null, 2)}
                </div>
              )
            ) : (
              <div className="message-content">{msg.content}</div>
            )}
          </div>
        ))}

        {loading && (
          <div className="status">
            <span className="status-dot loading"></span>
            thinking...
          </div>
        )}

        {error && (
          <div className="error">{error}</div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <div className="input-area">
        <textarea
          ref={textareaRef}
          value={input}
          onChange={(e) => {
            setInput(e.target.value);
            adjustTextareaHeight();
          }}
          onKeyDown={handleKeyDown}
          placeholder="type a message..."
          disabled={loading}
          rows={1}
        />
        <button
          className="send-btn"
          onClick={sendMessage}
          disabled={loading || !input.trim()}
        >
          send
        </button>
      </div>
    </div>
  );
}
