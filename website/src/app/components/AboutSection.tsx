import React from "react";
import Image from "next/image";
import Link from "next/link";
import { Download, ExternalLink } from "lucide-react";

interface AboutSectionProps {
  githubReleaseUrl: string;
}

export function AboutSection({ githubReleaseUrl }: AboutSectionProps) {
  return (
    <section id="about" className="py-24 px-6 sm:px-10">
      <div className="max-w-7xl mx-auto">
        <div className="p-10 sm:p-16 rounded-3xl bg-gradient-to-b from-[#141414] to-[#0D0D0D] border border-[#262626] relative overflow-hidden text-center flex flex-col items-center">
          <div className="w-16 h-16 rounded-2xl bg-black border border-[#262626] p-2 flex items-center justify-center mb-6 shadow-xl">
            <Image
              src="/habitme_logo_svg.svg"
              alt="HabitMe"
              width={48}
              height={48}
              className="rounded-lg"
            />
          </div>

          <h2 className="text-2xl sm:text-4xl font-extrabold tracking-tight mb-4">
            Ready to build distraction-free habits?
          </h2>
          <p className="text-sm sm:text-base text-[#8A8A8A] max-w-xl mb-8">
            Download the latest APK release from GitHub. No account setup,
            zero data collection, and completely open source.
          </p>

          <div className="flex flex-wrap items-center justify-center gap-4">
            <Link
              href={githubReleaseUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3.5 rounded-xl bg-[#22C55E] text-black font-semibold text-sm hover:bg-[#1eb054] transition shadow-md shadow-[#22C55E]/20 flex items-center gap-2"
            >
              <Download className="w-4 h-4" />
              <span>Download Latest Release</span>
            </Link>
            <Link
              href="https://www.itsmeprince.com"
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3.5 rounded-xl bg-black border border-[#262626] text-white font-semibold text-sm hover:bg-[#1c1c1c] transition flex items-center gap-2"
            >
              <ExternalLink className="w-4 h-4 text-[#8A8A8A]" />
              <span>Made By ItsMe Prince</span>
            </Link>
          </div>
        </div>
      </div>
    </section>
  );
}
