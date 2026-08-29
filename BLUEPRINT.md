# Riakoine Signal — Product Blueprint

**Version:** 1.0  
**Date:** August 2026  
**Author:** Riakoine Empire  

---

## 1. What It Is

Riakoine Signal is a real-time communication infrastructure built specifically for Africa. It handles WebRTC signaling, live video streaming, and participant coordination — the plumbing that makes video calls and live broadcasts work.

It is not a consumer product. It is infrastructure that other apps (starting with AWARE Organics Africa) sit on top of. Think of it the way Twilio is infrastructure for SMS, or how Cloudflare is infrastructure for the web.

The long-term goal: every agri-tech app, cooperative platform, health clinic, and rural education system in Africa that needs real-time video runs on Riakoine Signal — instead of routing money to Twilio, Dyte, or Zoom.

---

## 2. The Problem It Solves

Existing real-time communication infrastructure was built for the West:

- **Latency assumptions** — designed for fibre, not 3G or Starlink
- **Pricing** — per-minute billing that bleeds African startups dry at scale
- **No context** — generic video calls with no understanding of agriculture, cooperatives, health, or local language
- **CGNAT blind** — Starlink users (growing fast across Africa) sit behind carrier-grade NAT; most signaling servers fail for them without TURN relay
- **Data sovereignty** — call metadata, participant records, and session logs flow through servers in the US or EU

Riakoine Signal is built ground-up for African network conditions, African pricing realities, and African use cases.

---

## 3. Core Architecture

```
Client (browser / mobile app)
        │
        ▼
   WebSocket (Phoenix Channel)
        │
        ▼
┌─────────────────────────────────┐
│        Riakoine Signal          │
│                                 │
│  ┌─────────────┐  ┌──────────┐ │
│  │ Room Channel│  │Broadcast │ │
│  │ (WebRTC     │  │Channel   │ │
│  │  signaling) │  │(streaming│ │
│  └─────────────┘  └──────────┘ │
│                                 │
│  ┌─────────────┐  ┌──────────┐ │
│  │  Phoenix    │  │  FFmpeg  │ │
│  │  Presence   │  │  (HLS    │ │
│  │ (no ghosts) │  │  output) │ │
│  └─────────────┘  └──────────┘ │
│                                 │
│  Elixir/OTP — BEAM VM           │
│  (millions of concurrent        │
│   connections, self-healing)    │
└─────────────────────────────────┘
        │                │
        ▼                ▼
   Peer-to-peer     HLS segments
   WebRTC video     (viewers via
   (participants)    plain HTTP)
```

**Technology choices:**
- **Elixir + Phoenix** — BEAM VM handles massive concurrency with tiny memory footprint per connection. WhatsApp ran 2 million connections on a single Erlang node.
- **Phoenix Presence** — distributed participant tracking that automatically cleans up disconnected peers. Eliminates ghost tiles natively.
- **FFmpeg** — battle-tested media transcoding. Converts WebRTC streams to HLS for broadcast viewers.
- **Fly.io** — deployment platform with nodes in Johannesburg, London, and Chicago. Requests route to the nearest node automatically.

---

## 4. Features

### 4.1 Currently Built

| Feature | Description |
|---|---|
| WebRTC signaling | SDP offer/answer/ICE relay between peers |
| Phoenix Presence | Participant tracking, join/leave events, no ghost tiles |
| Per-room GenServer | Isolated room state, auto-cleanup after 30min idle |
| Live streaming | MediaRecorder → FFmpeg → HLS, ~4s latency |
| ICE/TURN endpoint | Time-limited TURN credentials for CGNAT/Starlink users |
| Room metadata | Attach crop type, farm ID, session type, language to rooms |
| Health endpoint | Live room count, region, node identity |
| GitHub Actions deploy | Push to main → auto-deploys to Fly.io |

### 4.2 Phase 2 — Reliability

| Feature | Why |
|---|---|
| Multi-node clustering | Johannesburg + London + Chicago nodes sharing Presence state via libcluster |
| Room state persistence | Survive node restarts without dropping active calls |
| Reconnection protocol | Client auto-reconnects to same room after network drop |
| TURN server (coturn) | Self-hosted, Africa-located, mandatory for Starlink users |
| Rate limiting | Prevent abuse, protect signaling server from floods |
| Auth tokens | Rooms require a signed token — no anonymous access |

### 4.3 Phase 3 — Intelligence

| Feature | Why |
|---|---|
| Adaptive quality hints | Signal network conditions to clients (2G → lower bitrate) |
| Session recording | Store HLS streams to R2/S3, tied to room metadata |
| Transcript integration | Pass audio to Whisper/Azure Speech, return timestamped text |
| Translation layer | Auto-translate transcripts (Swahili, Kikuyu, Luo, Dholuo) |
| Analytics pipeline | Session duration, participant counts, drop rates per region |
| Webhook events | Notify external apps when rooms start/end, participants join/leave |

### 4.4 Phase 4 — Platform

| Feature | Why |
|---|---|
| SDK (JavaScript) | One import, drop-in video calls for any African web app |
| REST API | Create rooms, issue tokens, query sessions programmatically |
| Developer dashboard | Usage stats, active rooms, billing, API keys |
| White-label | Custom domain, custom branding for enterprise customers |
| SFU mode | Selective Forwarding Unit for large group calls (50+ participants) |

---

## 5. Deployment Strategy

### Regions

| Region | Fly.io Node | Serves |
|---|---|---|
| Johannesburg (`jnb`) | Primary | East Africa, South Africa, Central Africa |
| Lagos (`lhr` → West Africa) | Secondary | West Africa, Nigeria, Ghana |
| London (`lhr`) | Tertiary | Diaspora, international partners |
| Chicago (`ord`) | Quaternary | Americas diaspora, US-based NGOs |

### Starlink Compatibility

Starlink is expanding rapidly across Kenya, Nigeria, South Africa, Rwanda, and Mozambique. It delivers 20–40ms latency versus 600ms for geostationary satellite — a genuine game changer for rural Africa.

However, Starlink uses carrier-grade NAT (CGNAT) by default. This means:
- WebRTC direct peer-to-peer connections fail
- TURN relay is mandatory, not optional
- Our `GET /api/ice-servers` endpoint always returns TURN credentials
- TURN servers are deployed in Johannesburg and London for low relay latency

Any African app that ignores Starlink CGNAT is building for yesterday's network. Riakoine Signal is built for tomorrow's.

---

## 6. Target Customers

### Tier 1 — Internal (AWARE Organics Africa)
The first customer. Farmer-to-extension-officer calls, cooperative training sessions, live crop demos. Validates the infrastructure at small scale before external rollout.

### Tier 2 — African Agri-Tech
Platforms serving smallholder farmers need real-time video for extension services but cannot afford Dyte/Twilio pricing at scale. Riakoine Signal offers fixed monthly pricing instead of per-minute billing.

Examples: farmer advisory apps, input company field demo platforms, cooperative management systems.

### Tier 3 — Rural Health
Community health workers doing teleconsultations need video that works on 3G and Starlink. Same infrastructure, different context layer.

### Tier 4 — NGOs and Development Organisations
USAID, FAO, GIZ, and county governments run farmer training programs. They need reliable video infrastructure with African data residency and Swahili support. They have budget and procurement processes.

### Tier 5 — African Edtech
Rural schools and vocational training centres need video that works where they are, not where Silicon Valley assumes they are.

---

## 7. Monetization

### Model: Fixed Monthly Tiers

Per-minute billing punishes growth. Fixed tiers reward it.

| Tier | Price | Included | Target |
|---|---|---|---|
| **Seed** | Free | 500 participant-minutes/month, 2 concurrent rooms | Internal testing, pilots |
| **Sprout** | $29/mo | 10,000 participant-minutes, 20 concurrent rooms | Small agri-tech apps |
| **Harvest** | $99/mo | 50,000 participant-minutes, unlimited rooms | Growing platforms |
| **Enterprise** | Custom | Unlimited, dedicated node, SLA, white-label | NGOs, governments |

### Additional Revenue
- **Recording storage** — $0.02/GB/month for stored session recordings
- **Transcription** — $0.01/minute for AI-generated session transcripts
- **TURN bandwidth** — included up to 10GB/month, $0.05/GB above

### Unit Economics
Infrastructure cost at steady state: ~$80/month (Fly.io + TURN VPS). A single Harvest customer at $99/month covers costs. Everything above is margin.

---

## 8. Competitive Positioning

| | Twilio | Dyte | Riakoine Signal |
|---|---|---|---|
| Pricing | Per-minute | Per-minute | Fixed monthly |
| Africa-first | No | No | Yes |
| Starlink CGNAT | Partial | No | Yes |
| Data residency | US/EU | US/EU | Africa (Johannesburg primary) |
| Agricultural context | No | No | Yes |
| Local language support | No | No | Built-in (Phase 3) |
| Open roadmap | No | No | Yes |

The moat is not the technology — WebRTC is a standard. The moat is **context**: rooms that know about crops, farms, cooperatives, and languages. That context makes Riakoine Signal sticky in ways a generic signaling server cannot replicate.

---

## 9. Roadmap

| Phase | Timeline | Milestone |
|---|---|---|
| **0 — Foundation** | Done | Signaling, streaming, ICE, deploy pipeline |
| **1 — Deploy** | When Fly.io access available | Live at riakoine-signal.fly.dev |
| **2 — AWARE integration** | After deploy | AWARE Organics Africa fully off Dyte |
| **3 — Reliability** | Month 2–3 | Multi-node, reconnection, auth tokens, TURN |
| **4 — Intelligence** | Month 4–6 | Recording, transcription, translation, analytics |
| **5 — Platform** | Month 6–12 | SDK, API, developer dashboard, first external customer |
| **6 — Scale** | Year 2 | SFU, 10+ enterprise customers, 1M+ participant-minutes/month |

---

## 10. Success Metrics

| Metric | 6-month target | 12-month target |
|---|---|---|
| Active rooms (peak concurrent) | 10 | 100 |
| Paying customers | 1 (AWARE internal) | 5 external |
| Monthly participant-minutes | 5,000 | 100,000 |
| Infrastructure cost | $80/mo | $200/mo |
| Revenue | $0 (internal) | $500/mo |
| TURN relay success rate | >95% | >99% |
| Call setup latency (Nairobi) | <2s | <1s |

---

## 11. What This Is Not

- **Not a consumer product** — farmers never open riakoine-signal.fly.dev directly
- **Not a replacement for Starlink** — it runs on top of whatever network is available
- **Not a recording platform** — recordings are a feature, not the product
- **Not global-first** — Africa is the focus; global reach follows African success

---

*Built on Elixir/OTP. Deployed on Fly.io. Designed for the continent.*
