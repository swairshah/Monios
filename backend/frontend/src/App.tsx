import { useState, useEffect, useRef } from "react";

interface Message {
  id: string;
  type: "user" | "assistant" | "system";
  content: string;
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

function getInitialUserId(): string {
  return localStorage.getItem("monios-user") || "guest";
}

export default function App() {
  const [dark, setDark] = useState(getInitialTheme);
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [userId, setUserId] = useState(getInitialUserId);
  const [editingUser, setEditingUser] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const userInputRef = useRef<HTMLInputElement>(null);

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
    // Clear server-side session
    try {
      await fetch("/chat/clear", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ user_id: userId }),
      });
    } catch {
      // Ignore clear errors
    }
  };

  const saveUserId = (newId: string) => {
    const trimmed = newId.trim() || "guest";
    setUserId(trimmed);
    localStorage.setItem("monios-user", trimmed);
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
      const response = await fetch("/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: trimmed, user_id: userId }),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const text = await response.text();
      const lines = text.split("\n");

      for (const line of lines) {
        if (line.startsWith("data: ")) {
          const data = line.slice(6);
          try {
            const parsed = JSON.parse(data);

            if (parsed.type === "assistant" && parsed.message?.content) {
              for (const block of parsed.message.content) {
                if (block.type === "text") {
                  setMessages(prev => [...prev, {
                    id: generateId(),
                    type: "assistant",
                    content: block.text,
                  }]);
                }
              }
            } else if (parsed.type === "result") {
              // Final result message
              if (parsed.result) {
                setMessages(prev => [...prev, {
                  id: generateId(),
                  type: "assistant",
                  content: parsed.result,
                }]);
              }
            } else if (parsed.content) {
              // Simple response format
              setMessages(prev => [...prev, {
                id: generateId(),
                type: "assistant",
                content: parsed.content,
              }]);
            }
          } catch {
            // Not JSON, treat as plain text
            if (data.trim()) {
              setMessages(prev => [...prev, {
                id: generateId(),
                type: "assistant",
                content: data,
              }]);
            }
          }
        }
      }

      // If no SSE data found, try parsing as plain JSON
      if (!text.includes("data: ")) {
        try {
          const json = JSON.parse(text);
          if (json.content) {
            setMessages(prev => [...prev, {
              id: generateId(),
              type: "assistant",
              content: json.content,
            }]);
          }
        } catch {
          // Plain text response
          if (text.trim()) {
            setMessages(prev => [...prev, {
              id: generateId(),
              type: "assistant",
              content: text,
            }]);
          }
        }
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
        <span className="logo">~ monios</span>
        <div className="header-actions">
          {editingUser ? (
            <input
              ref={userInputRef}
              className="user-input"
              defaultValue={userId}
              onBlur={(e) => saveUserId(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") saveUserId(e.currentTarget.value);
                if (e.key === "Escape") setEditingUser(false);
              }}
            />
          ) : (
            <button
              className="user-btn"
              onClick={() => setEditingUser(true)}
              title="Click to change user"
            >
              @{userId}
            </button>
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
            send a message to start chatting
          </div>
        )}

        {messages.map((msg) => (
          <div key={msg.id} className={`message ${msg.type}`}>
            <div className="message-content">{msg.content}</div>
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
