import React from "react";
import { Zap, Sparkles, ShieldCheck, WifiOff, Database, Download } from "lucide-react";

export function FeaturesSection() {
  return (
    <section id="features" className="py-24 px-6 sm:px-10">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight mb-4">
            Designed for ruthless discipline.
          </h2>
          <p className="text-base sm:text-lg text-[#8A8A8A] max-w-xl mx-auto">
            Every detail is engineered to help you build habits without
            distractions, accounts, or unnecessary complexities.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Feature 1 */}
          <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-[#22C55E]">
                <Zap className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">
                Live Recurrence Resets
              </h3>
              <p className="text-sm text-[#8A8A8A] leading-relaxed">
                Recurring habits automatically transition to completed with
                a live countdown. Once the cycle finishes, they reset back
                to active and notify you immediately.
              </p>
            </div>
            <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-[#22C55E] flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" />
              Lazy scheduler reconciliation
            </div>
          </div>

          {/* Feature 2 */}
          <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-[#FF8A00]">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">
                Zero Network Permissions
              </h3>
              <p className="text-sm text-[#8A8A8A] leading-relaxed">
                No tracking scripts, no cloud logins, and no internet access
                declared in the Android manifest. Your personal routines
                stay strictly on your phone.
              </p>
            </div>
            <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-[#FF8A00] flex items-center gap-1.5">
              <WifiOff className="w-3.5 h-3.5" />
              100% Privacy by design
            </div>
          </div>

          {/* Feature 3 */}
          <div className="p-8 rounded-3xl bg-[#0D0D0D] border border-[#262626] hover:border-[#383838] transition flex flex-col justify-between">
            <div>
              <div className="w-12 h-12 rounded-2xl bg-[#141414] border border-[#262626] flex items-center justify-center mb-6 text-white">
                <Database className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold mb-2">
                Native SQL Dump & Restore
              </h3>
              <p className="text-sm text-[#8A8A8A] leading-relaxed">
                Export complete SQLite database dumps anytime. Import or
                merge your backups across devices without relying on any
                subscription cloud locker.
              </p>
            </div>
            <div className="mt-8 pt-4 border-t border-[#262626] text-xs font-mono text-white flex items-center gap-1.5">
              <Download className="w-3.5 h-3.5" />
              Full data ownership
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}

