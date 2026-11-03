# Hyprwise Backend Server

A decoupled, lightweight [Hono](https://hono.dev) backend server powering:
- **User Authentication**: Google Sign-In & Apple Sign-In token verification and sessions.
- **Hyprwise Cloud Sync Engine (Pro Plan)**: End-to-end encrypted backup, snapshot sync, and multi-device restoration.
- **Gemini AI MCP Proxy**: Secure server-side gateway to Google Gemini AI (1.5 Flash), executing Model Context Protocol (MCP) function calling tools locally on the client without exposing API keys.

## Quick Start

### Using Bun (Recommended)
```bash
cd server
bun install
bun run dev
```

### Using Node.js
```bash
cd server
npm install
npm run dev
```

## API Endpoints

- `GET /health` - Health check
- `POST /api/auth/google` - Google OAuth authentication
- `POST /api/auth/apple` - Apple ID authentication
- `GET /api/auth/me` - Profile & Pro subscription status
- `POST /api/sync/push` - Push client financial snapshot to cloud
- `GET /api/sync/pull` - Pull latest synced data
- `GET /api/sync/status` - Sync status and metadata
- `POST /api/ai/chat` - Gemini AI chat with function-calling support
