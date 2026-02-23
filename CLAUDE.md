# CLAUDE.md — Campus Bar Ranking Platform (Mizzou MVP)

You are building a production-ready web application for ranking bars near the University of Missouri.

This file defines BOTH:
- Business architecture rules
- Frontend automation & screenshot workflow rules

No exceptions.

---

# CORE OBJECTIVE

Build a mobile-first nightlife ranking platform that:

- Ranks bars nightly
- Allows student check-ins and voting
- Displays rankings by category
- Includes a chatbot interface
- Supports bar owner dashboards
- Is campus-specific (Mizzou first)

The product must be simple, fast, and usable by drunk college students.

---

# TECH STACK

Frontend:
- Next.js (App Router preferred)
- TypeScript
- TailwindCSS via CDN unless specified otherwise
- Mobile-first
- Supabase Auth (client-side session only)

Backend:
- Supabase Postgres
- Supabase Edge Functions
- Row-Level Security enabled
- Deterministic ranking logic (SQL or Edge Function)

AI Layer:
- Claude API used ONLY for:
  - Formatting chatbot responses
  - Interpreting scraped text
- Claude NEVER computes ranking scores
- Claude NEVER stores secrets

Scraping Layer:
- Firecrawl MCP
- Structured JSON extraction only

---

# USER ROLES

1. Student User
2. Bar Owner
3. Admin (internal only)

Each must have protected routes.

---

# REQUIRED DATABASE TABLES

bars  
users  
check_ins  
poll_responses  
bar_instagram_metrics  
bar_daily_scores  

All ranking calculations happen in bar_daily_scores.

---

# RANKING CATEGORIES (MVP)

- Most Fun Tonight
- Best Value
- Most Freshman Friendly
- Best $10 Meal
- Overall

Ranking logic must be deterministic and backend-computed.

---

# MVP FEATURE LIST

1. Landing Page
2. Auth (User + Bar mode)
3. Rankings Page (5 tabs)
4. Individual Bar Page
5. Check-In System
6. Poll Sliders
7. Chatbot UI
8. Admin Dashboard
9. Bar Owner Dashboard

Do not build features outside MVP scope.

---

# FRONTEND RULES (MANDATORY)

## Always Do First
- Invoke the `frontend-design` skill before writing frontend code.
- No exceptions.

## Reference Images
- If reference image provided:
  - Match layout, spacing, typography, color EXACTLY.
  - Use placeholders (`https://placehold.co/`)
  - Do NOT improve or add.
- If no reference:
  - Design with high craft using guardrails below.

Perform at least TWO screenshot comparison passes before finishing.

---

# LOCAL SERVER RULES

- Always serve on localhost.
- Never screenshot file:/// URLs.
- Start dev server:
  node serve.mjs

Serves:
  http://localhost:3000

If running, do not start a second instance.

---

# SCREENSHOT WORKFLOW

- Use Puppeteer at:
  C:/Users/nateh/AppData/Local/Temp/puppeteer-test/

- Screenshot:
  node screenshot.mjs http://localhost:3000

Saved to:
  ./temporary screenshots/screenshot-N.png

After screenshot:
- Read PNG from temporary screenshots/
- Compare spacing, font size, color hex, shadows, border-radius
- Fix mismatches
- Re-screenshot
- Minimum 2 rounds

Do not stop early.

---

# OUTPUT DEFAULTS

- Single index.html file unless told otherwise
- All styles inline
- Tailwind CDN
- Placeholder images
- Mobile-first responsive

---

# BRAND ASSETS

Always check:
  /brand_assets/

If logos/colors exist:
- Use them
- Do not invent new palette

---

# ANTI-GENERIC DESIGN GUARDRAILS

Colors:
- NEVER use default Tailwind blue/indigo
- Create custom brand primary

Shadows:
- No flat shadow-md
- Use layered, color-tinted shadows

Typography:
- Different font for headings and body
- Tight tracking (-0.03em) on large headings
- Body line-height: 1.7+

Gradients:
- Use layered radial gradients
- Add subtle grain texture

Animations:
- Only transform + opacity
- Never transition-all
- Use spring-style easing

Interactive states:
- Hover
- Focus-visible
- Active
Required for ALL clickable elements.

Images:
- Gradient overlay (bg-gradient-to-t from-black/60)
- Color blend layer

Spacing:
- Consistent spacing system
- No random Tailwind steps

Depth:
- Clear layering (base → elevated → floating)

---

# BACKEND RULES

- NEVER compute rankings in frontend
- NEVER expose service role key
- Use deterministic SQL functions
- Store AI output as structured JSON
- AI informs, backend decides

---

# CHATBOT RULES

Chatbot flow:

User Question  
↓  
Backend fetch ranking data  
↓  
Claude formats response  
↓  
Return to frontend  

Do NOT:
- Run autonomous multi-agent systems
- Let Claude compute rankings
- Let Claude directly access database

Claude is formatting + reasoning layer only.

---

# SECURITY RULES

- RLS enabled on all tables
- Bar owners can only edit their bar
- Users can only vote once per defined interval
- Admin routes protected

---

# DESIGN PRINCIPLES

- Mobile-first
- One-tap actions
- Large buttons
- Minimal typing
- Dark nightlife aesthetic
- Fast load speed
- Simple navigation

Freshman test:
A freshman must be able to:
- Open the site
- See rankings
- Check in
- Vote
- Ask chatbot
All within 30 seconds.

---

# DO NOT BUILD

- National scaling logic
- Prediction engine
- Complex AI agents
- Microservices
- Blockchain anything
- Over-engineered state management

---

# MVP PRIORITY ORDER

1. Auth
2. Bars table
3. Ranking display
4. Check-in system
5. Poll system
6. Score computation
7. Chatbot formatting
8. Bar dashboards
9. Admin dashboard

---

# SUCCESS CRITERIA

If a group of Mizzou freshmen says:

"Where are we going tonight?"
and someone replies:
"Check the app."

You succeeded.