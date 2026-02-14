# OpenClaw Token Optimization Guide
**Complete guide to reduce unnecessary token burn while maintaining quality**

---

## Quick Start: Top 3 Immediate Wins

### 1. Reset Sessions Regularly (Saves 40-60%)
OpenClaw accumulates context indefinitely. Every message, tool output, and file stays in memory.

**Commands:**
- `/status` - Check current token usage
- `/compact` - Summarize and compress session history
- `/new` or `/reset` - Start completely fresh

**Rule:** Reset after every independent task (finished coding, completed PR review, done debugging)

### 2. Switch to Cheaper Models (Saves 50-70%)
Model pricing per 1M tokens (Feb 2026):
- **Kimi K2.5 (Recommended)**: Highly efficient and cost-effective
- **Haiku**: ~$0.80
- **Sonnet**: ~$3.00 (expensive)
- **Opus**: ~$30.00 (very expensive)

**Quick config** (`~/.openclaw/openclaw.json`):
```json5
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/moonshotai/kimi-k2.5"
      }
    }
  }
}
```

**CLI command:**
```bash
openclaw model set openrouter/moonshotai/kimi-k2.5
```

### 3. Disable Thinking Mode by Default (Saves 10-50x)
Thinking mode can explode token usage by 10-50x for simple tasks.

**Set global default:**
```json5
{
  "agents": {
    "defaults": {
      "thinkingDefault": "off"
    }
  }
}
```

**Enable only when needed:**
```
/think:high Analyze our Q4 token economics and propose optimizations
```

---

## Smart Thinking Mode: Use It Only When Needed

### Manual Per-Message Control

**For simple tasks (no thinking):**
```
/think:off Check my calendar for today
```

**For complex tasks (enable thinking):**
```
/think:high Debug this complex smart contract interaction issue
```

**Thinking levels:**
- `off` - No reasoning (fastest, cheapest)
- `minimal` or `low` - Light reasoning
- `medium` - Moderate reasoning
- `high` - Maximum reasoning

**Session-based default:**
```
/think:off
```
Now all messages use no thinking until you change it.

**Check current level:**
```
/think
```

### Automated Routing with Multi-Agent Profiles

**Config: `~/.openclaw/openclaw.json`**
```json5
{
  "agents": {
    "defaults": {
      "thinkingDefault": "off"
    },
    "list": [
      {
        "id": "quick",
        "name": "Quick Tasks",
        "default": true,
        "workspace": "~/openclaw-quick",
        "model": "moonshotai/kimi-k2.5"
      },
      {
        "id": "deep",
        "name": "Deep Work",
        "workspace": "~/openclaw-deep",
        "model": "anthropic/claude-opus-4-5",
        "thinkingDefault": "high"
      }
    ]
  }
}
```

**Usage:**
```bash
# Simple task → default agent (no thinking)
openclaw agent send "Check my calendar"

# Complex task → deep work agent (thinking enabled)
openclaw agent send --agent deep "Analyze token economics and suggest improvements"
```

### Cost Impact of Thinking Mode

| Scenario | Without Thinking | With Thinking | Multiplier |
|----------|------------------|---------------|------------|
| Simple query | 5K tokens | 50K tokens | **10x** |
| Complex task | 20K tokens | 400K tokens | **20x** |
| Heartbeat | 3K tokens | 30K tokens | **10x** |

---

## Core Optimization Strategies

### 1. Cache Optimization (Saves 30-50%)
System prompts (5K-10K tokens) get sent with every request. Prompt caching is handled automatically by supported providers (like Anthropic), but configuration affects hit rates.

```json5
{
  "agents": {
    "defaults": {
      "models": {
        "openrouter/moonshotai/kimi-k2.5": {
          "alias": "kimi-k2.5",
          "params": {
            "temperature": 0.2 // Critical for cache hits: consistent params = better hits
          }
        }
      }
    }
  }
}
```

**Key:** Lower temperature (0.2) and consistent settings dramatically improve cache hit rate because exact parameter matches are required for cache retrieval.

### 2. Context Window Limits (Saves 20-40%)
Default 200K+ token context encourages waste. Force discipline:

```json5
{
  "agents": {
    "defaults": {
      "contextTokens": 50000,  // Reduce from default to 50K-100K
      "compaction": {
        "mode": "safeguard",
        "reserveTokensFloor": 32000
      },
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "30m",  // Drop old messages after 30 min inactivity
        "keepLastAssistants": 3
      }
    }
  }
}
```

### 3. Optimize Heartbeats (Major Savings)
Heartbeats run continuously and burn tokens in the background.

```json5
{
  "agents": {
    "defaults": {
      "heartbeat": {
        "every": "30m",  // String format (e.g. "30m", "1h"). Never below 5m.
        "model": "moonshotai/kimi-k2.5",
        "includeReasoning": false
      }
    }
  }
}
```

**Critical:** Keep `HEARTBEAT.md` minimal—a short checklist, not a full document. Large files multiply token cost at every heartbeat.

### 4. Disable Unnecessary Skills (Saves 10-15%)
Each skill adds tokens to the system prompt. Use `tools.allow` or `tools.deny` to restrict them.

```json5
{
  "agents": {
    "defaults": {
      "tools": {
        "profile": "coding", // Start with a profile (minimal, coding, messaging, full)
        "deny": ["browser", "canvas", "gmail", "calendar"] // Explicitly disable expensive tools
      }
    }
  }
}
```

### 5. Sub-Agent Configuration (Saves 80%)
Use cheap models for sub-agents handling simple sub-tasks.

```json5
{
  "agents": {
    "defaults": {
      "subagents": {
        "maxConcurrent": 8,
        "model": "openrouter/moonshotai/kimi-k2.5"
      }
    }
  }
}
```

**Use isolated sessions for heavy tasks:**
```json5
{
  "cron": {
    "enabled": true,
    "jobs": [
      {
        "schedule": "0 * * * *",
        "command": "agent --thinking off --message 'Check mentions'",
        "sessionTarget": "isolated"
      }
    ]
  }
}
```

### 6. Smart Session Initialization
Don't auto-load everything on startup. Add to `SOUL.md`:

```markdown
## SESSION INITIALIZATION RULE

On every session start:

1. Load ONLY:
   - SOUL.md
   - USER.md
   - IDENTITY.md
   - memory/YYYY-MM-DD.md (if exists)

2. DO NOT auto-load:
   - MEMORY.md
   - Session history
   - Prior messages
   - Previous tool outputs

3. When user asks about prior context:
   - Use memory_search() on demand
   - Pull only relevant snippet with memory_get()
   - Don't load the whole file

4. Update memory/YYYY-MM-DD.md at session end with:
   - What you worked on
   - Decisions made
   - Next steps
```

### 7. Context Triangulation
Don't feed entire files. For code changes, provide only:
- That function's code
- Signatures of functions it calls
- Related type definitions

Can reduce context by 70-80%.

---

## Complete Working Configuration

**File: `~/.openclaw/openclaw.json`** (tested and confirmed working)

```json5
{
  "agents": {
    "defaults": {
      // Model selection
      "model": {
        "primary": "openrouter/moonshotai/kimi-k2.5"
      },

      // Model-specific settings with aliases
      "models": {
        "openrouter/moonshotai/kimi-k2.5": {
          "alias": "kimi-k2.5",
          "params": {
            "temperature": 0.2 // Optimization for cache hits
          }
        },
        "openrouter/anthropic/claude-haiku-4-5": {
          "alias": "claude-haiku-4-5",
          "params": {
            "temperature": 0.2 // Optimization for cache hits
          }
        }
      },

      // Workspace path
      "workspace": "/home/node/.openclaw/workspace",

      // Context limits
      "contextTokens": 50000,

      // Context pruning
      "contextPruning": {
        "mode": "cache-ttl",
        "ttl": "30m",
        "keepLastAssistants": 3
      },

      // Compaction
      "compaction": {
        "mode": "safeguard",
        "reserveTokensFloor": 32000
      },

      // Global thinking default
      "thinkingDefault": "off",

      // Block streaming settings
      "blockStreamingDefault": "on",
      "blockStreamingBreak": "message_end",
      "blockStreamingChunk": {
        "breakPreference": "paragraph"
      },

      // Heartbeat
      "heartbeat": {
        "every": "30m",
        "model": "moonshotai/kimi-k2.5",
        "includeReasoning": false
      },

      // Concurrency
      "maxConcurrent": 4,

      // Sub-agents
      "subagents": {
        "maxConcurrent": 8,
        "model": "openrouter/moonshotai/kimi-k2.5"
      }
    }
  }
}
```

> **Note:** This is a proven production configuration. The multi-agent setup and cron jobs shown in earlier sections are optional additions you can layer on top.

---

## Real-World Results

| Optimization | Cost Before | Cost After | Savings |
|--------------|-------------|------------|---------|
| Session Management | $50/mo | $20/mo | 60% |
| Model Switching | $80/mo | $25/mo | 69% |
| Cache Optimization | $40/mo | $20/mo | 50% |
| Thinking Control | $60/mo | $10/mo | 83% |
| **Combined** | **$347/mo** | **$35/mo** | **90%** |

User-reported results:
- $347 → $68/month (80% savings)
- $90 → $6 for overnight tasks (97% savings)
- 300K → 20K tokens per process with sub-agent optimization

---

## Commands Reference

### Session Management
```bash
/status              # Check token usage
/compact             # Compress session history
/new                 # Start fresh session
/reset               # Same as /new
```

### Thinking Control
```bash
/think               # Check current thinking level
/think:off           # Disable thinking
/think:low           # Minimal reasoning
/think:medium        # Moderate reasoning
/think:high          # Maximum reasoning
/t off               # Shorthand for /think:off
/t high              # Shorthand for /think:high
```

### Model Management
```bash
openclaw models status                    # List available models
openclaw model set <model-name>           # Switch model
openclaw agent send --agent deep "..."    # Route to specific agent
```

### Configuration
```bash
openclaw gateway restart                  # Apply config changes
```

### Session File Management
```bash
rm -rf ~/.openclaw/agents.main/sessions/*.jsonl  # Delete session files
```

---

## Implementation Roadmap

### Do This Today (5 minutes)
1. Check token usage: `/status`
2. Set global thinking default to `off` in config
3. Switch default model to `moonshotai/kimi-k2.5`
4. Restart gateway: `openclaw gateway restart`

### This Week (30 minutes)
1. Add cache optimization settings (temperature 0.2 in model params)
2. Set context limits (50K-100K tokens)
3. Optimize heartbeat interval (≥5 minutes, using string format "5m")
4. Disable unused skills via `tools.deny`
5. Configure sub-agents with cheap models
6. Test `/compact` and `/new` commands

### Build These Habits (Ongoing)
- Reset session after every completed task: `/compact` or `/new`
- Monitor `/status` regularly (check context % before big tasks)
- Use `/think:off` for simple tasks, `/think:high` for complex analysis
- Keep HEARTBEAT.md minimal
- Keep workspace files small and focused

### Advanced Optimization (Optional)
- Set up multi-agent profiles for different workload types
- Configure session initialization rules in SOUL.md
- Implement context triangulation for code tasks
- Set up isolated sessions for cron jobs
- **Local Models (Optional):** Install local models with Ollama as an additional potential improvement for zero-cost simple tasks, though this requires dedicated hardware.

---

## Troubleshooting

### "Context length exceeded" errors
**Solutions:**
- Run `/compact` immediately
- If that fails, use `/new` to start fresh
- Lower `contextTokens` to 50K-100K in config
- Enable aggressive compaction mode
- Set contextPruning with shorter TTL

### Still burning through tokens
**Check:**
- Heartbeat frequency (should be ≥5 minutes)
- Thinking mode is disabled by default
- Using cheap model as default (Kimi K2.5)
- HEARTBEAT.md file size (keep minimal)
- Large workspace files
- Sub-agents using cheap models
- Cron jobs have `--thinking off` flag

### Cache not working
**Solutions:**
- Set temperature to 0.2 in `models.<id>.params` (critical for cache hits)
- Ensure heartbeat interval < cache TTL (usually 1h)
- Restart gateway after config changes

### Context overflow despite limits
**Solutions:**
- Use `/compact` more frequently
- Enable aggressive compaction
- Lower `contextTokens` further (try 30K)
- Implement session initialization rules
- Use context triangulation (provide only relevant code/context)

### Thinking mode still active
**Check resolution order:**
1. Inline directive (highest priority) - `/think:off` in message
2. Session override - Send `/think:off` as standalone message
3. Global default - `thinkingDefault` in config
4. Model default - `agents.defaults.models` params

Make sure all levels are set to `off` or `disabled`.

---

## Key Principles Summary

1. **Reset aggressively** - Context accumulates silently; reset after every task
2. **Default to cheap** - Use Kimi K2.5 by default, upgrade only when needed
3. **Thinking off by default** - Enable thinking only for genuinely complex tasks
4. **Cache everything** - Low temperature = better cache hits
5. **Limit context** - 50K-100K is plenty for most work
6. **Optimize heartbeats** - Long intervals (e.g. "30m"), minimal files, cheap models
7. **Isolate heavy work** - Use separate agents or isolated sessions for automation
8. **Monitor constantly** - Check `/status` before and after big tasks

---

## Configuration File Location

**Main config:**
- `~/.openclaw/config.json5`
- `~/.openclaw/openclaw.json`

**Session files:**
- `~/.openclaw/agents.main/sessions/*.jsonl`

**Workspace-specific:**
- `~/[workspace]/SOUL.md`
- `~/[workspace]/HEARTBEAT.md`
- `~/[workspace]/USER.md`

**Apply changes:**
```bash
openclaw gateway restart
```

---

## Additional Resources

- **OpenClaw docs:** https://docs.openclaw.ai/
- **Model pricing:** https://openrouter.ai/
- **Cost calculator:** https://calculator.vlvt.sh
- **Config examples:** https://github.com/openclaw/openclaw

---

## Quick Reference Card

| What | Command/Setting | Impact |
|------|----------------|--------|
| **Disable thinking** | `"thinkingDefault": "off"` | 10-50x savings |
| **Reset session** | `/compact` or `/new` | 40-60% savings |
| **Use Kimi K2.5** | `"primary": "moonshotai/kimi-k2.5"` | 50-70% savings |
| **Enable caching** | `"params": { "temperature": 0.2 }` | 30-50% savings |
| **Limit context** | `"contextTokens": 50000` | 20-40% savings |
| **Optimize heartbeat** | `"heartbeat": { "every": "30m" }` | Major savings |
| **Cheap sub-agents** | `"subagents": { "model": "..." }` | 80% savings |
| **Enable thinking** | `/think:high` before message | Use sparingly |

---

**Last Updated:** February 14, 2026

**Version:** 1.3

**Target:** OpenClaw users experiencing high token burn costs

**Expected Impact:** 70-90% cost reduction with proper implementation
