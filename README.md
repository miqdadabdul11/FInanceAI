# AI Personal Finance System

Sistem pencatatan keuangan pribadi otomatis berbasis WhatsApp dan Web Dashboard.
Pengguna mengirim pesan transaksi sehari-hari melalui WhatsApp ("parkir 2k"), AI memahami dan menstrukturkannya, data divalidasi dan disimpan ke Supabase, kemudian divisualisasikan melalui Web Dashboard.

## Arsitektur & Teknologi
- **Frontend**: React + Vite + Tailwind CSS + Recharts (Deploy: Vercel)
- **Backend**: Node.js + Express + Zod (Deploy: Railway/Render)
- **Database & Auth**: Supabase (PostgreSQL + RLS)
- **AI**: OpenAI API Structured Output (`aiClient` wrapper)
- **WhatsApp**: WhatsApp Cloud API (Meta)

## Struktur Folder
```text
C:\4. Me\Finance\
  frontend/
  backend/
    src/
      ai/          # Wrapper LLM & prompt parser
      lib/         # Supabase client, logger, helper
      routes/      # Endpoint Express (webhook, api)
      services/    # Business logic transaksi & saldo
      validators/  # Skema validasi Zod
  .env.example
  .gitignore
  README.md
```
