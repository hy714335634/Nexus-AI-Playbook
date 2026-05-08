---
title: Stream Relay
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/sessions.py
    - nexus_utils/runtime_workspace/**
  generated_at: 2026-05-08T15:51:37+00:00
  generated_by: docs-sync v2
---

# Stream Relay

## What it is

Stream relay makes the agent's reply appear token-by-token, like a typewriter, while the full turn is buffered on the server. You can switch tabs, refresh the browser, or lose network briefly — when you return to the session, the stream picks up where it left off, with no messages or tool calls lost.

## When you'll use it

| Scenario | What you do | What the relay does |
| --- | --- | --- |
| Long task, you walk away | The agent is mid-way through a multi-step task and you switch to another session or tab | When you return, output resumes from the breakpoint and plays through to the end |
| Accidental disconnect | Network blips, laptop sleeps, page crashes | The client reconnects automatically — no need to re-ask, no duplicate execution |
| Viewing from two places | Same session open on phone and desktop | Both clients subscribe to the same stream independently and stay in sync |
| Re-check what just happened | You want to re-read a reply you just saw | Re-entering the session replays the backlog in one shot, then catches up to live |
| Slow tool call in flight | The agent is running a long-running tool | The connection stays alive, so proxies and browsers don't close it |

## How to use it

Stream relay is **on by default** — nothing to toggle. The steps below describe what you'll see as a user.

1. **Start a chat**
   Type a prompt in the chat panel and send. The agent's reply begins streaming in; tool calls (file reads, web searches, etc.) appear as cards inside the stream.
   <!-- SCREENSHOT: stream-relay-typing -->

2. **Switch tabs or leave the page**
   Click into another session or navigate away. The task keeps running on the server and output keeps accumulating.

3. **Return to the original session**
   Click back into the session. You will see:
   - The backlog **renders in one shot** (the catch-up phase)
   - The view then transitions into **live streaming** for any remaining output
   <!-- SCREENSHOT: stream-relay-catchup -->

4. **(Optional) Check session status**
   If you want to confirm whether a task is still running, the status indicator at the top shows one of `running` / `done` / `error`.

5. **Task finishes**
   Once the agent is done, the final message is persisted to message history and tool cards collapse into summaries. Re-entering later loads from message history directly — no more streaming.

::: tip
Short disconnects (tens of seconds) are nearly invisible. If you're away for a long time, the raw stream may have expired — the UI will say "please reload from message history", and you'll still see the full saved conversation once you re-open the session.
:::

## Key parameters & limits

| Item | Detail |
| --- | --- |
| Auto reconnect | Tab switching, refresh, and short network drops are handled automatically |
| Retention | Streaming events are buffered for a limited window on the server; once a task finishes and the window expires, load from message history instead |
| Multi-client | The same session can be subscribed from multiple tabs or devices at once; content stays consistent and the agent never re-runs |
| Tool-call summaries | To keep packets small, tool input in the stream is truncated to 100 characters and tool output to 2000 characters; full content is available in the workspace file panel |
| Idle heartbeat | When idle, the server emits a heartbeat every ~15 seconds to keep the connection alive through proxies |
| Catch-up signal | When you return to a session, the system emits a one-shot signal at the moment "backlog ends, live begins" so the UI can switch render modes |
| When the stream ends | After the server emits a `done` signal and drains the buffer, or if the agent errors out |
| Permissions | Streaming features require permission to chat with the agent |

## FAQ

**Q: When I return to a session, sometimes old content appears all at once, sometimes it types out — why?**
A: If the task finished while you were away, you see the full persisted message right away. If it's still running, you first see the missed backlog rendered in one shot, then the view enters live-typing mode.

**Q: I was offline for a long time and the page came back empty — is my output lost?**
A: The stream buffer is temporary, but the full message is written to history once the task completes. Re-open the session from the sidebar and you'll see everything — only the typewriter animation is gone.

**Q: If I have the same session open on my phone and laptop, do they conflict?**
A: No. Both clients subscribe to the same server-side stream, see identical content, and never cause the agent to execute the task twice.

**Q: The page shows "stream expired or not found" — what does that mean?**
A: The streaming buffer has aged out of its retention window. Your history is safe; just load the message list. You just won't see the live typewriter effect.

**Q: Why do tool calls in the stream look truncated?**
A: To keep the stream responsive, tool payloads are summarized. For the complete content, open the corresponding file in the session's workspace panel.
