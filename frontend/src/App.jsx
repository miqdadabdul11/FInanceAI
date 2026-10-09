import { useState } from 'react';

export default function App() {
  const [clicked, setClicked] = useState(false);

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center p-6 relative overflow-hidden">
      {/* Background Glow Effect */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute bottom-1/4 right-1/3 w-80 h-80 bg-cyan-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* Main Glassmorphic Card */}
      <main className="relative z-10 max-w-lg w-full bg-slate-900/80 backdrop-blur-xl border border-slate-800 rounded-2xl p-8 shadow-2xl shadow-emerald-950/20 text-center">
        {/* Status Badge */}
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-semibold mb-6">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          Frontend Phase 1 Ready
        </div>

        {/* Heading */}
        <h1 className="text-3xl font-extrabold tracking-tight text-white mb-3">
          AI Personal Finance
        </h1>
        <p className="text-slate-400 text-sm leading-relaxed mb-6">
          Sistem pencatatan keuangan pintar via WhatsApp & Web Dashboard.
          Setup React, Vite, dan Tailwind CSS berhasil berjalan dengan baik!
        </p>

        {/* Tech Stack Pills */}
        <div className="grid grid-cols-3 gap-2 mb-6">
          <div className="bg-slate-800/60 border border-slate-700/50 rounded-xl p-3 text-center">
            <p className="text-xs text-slate-400 font-medium">Framework</p>
            <p className="text-sm font-bold text-cyan-400 mt-0.5">React 19</p>
          </div>
          <div className="bg-slate-800/60 border border-slate-700/50 rounded-xl p-3 text-center">
            <p className="text-xs text-slate-400 font-medium">Bundler</p>
            <p className="text-sm font-bold text-purple-400 mt-0.5">Vite 6</p>
          </div>
          <div className="bg-slate-800/60 border border-slate-700/50 rounded-xl p-3 text-center">
            <p className="text-xs text-slate-400 font-medium">Styling</p>
            <p className="text-sm font-bold text-emerald-400 mt-0.5">Tailwind v4</p>
          </div>
        </div>

        {/* Interactive Verification Button */}
        <div className="pt-2">
          <button
            id="btn-test-interactive"
            onClick={() => setClicked(!clicked)}
            className="w-full py-3 px-4 rounded-xl font-semibold text-sm transition-all duration-200 cursor-pointer shadow-lg active:scale-95 bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold"
          >
            {clicked ? '🎉 React State Berfungsi Normal!' : 'Uji Interaktivitas React'}
          </button>
        </div>

        {/* Footer info */}
        <p className="text-slate-500 text-xs mt-6">
          Target Selanjutnya: Setup Backend Express (GET /health)
        </p>
      </main>
    </div>
  );
}
