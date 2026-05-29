import Link from "next/link";
import { useRouter } from "next/router";
import React from "react";

const navLinks = [
  { href: "/", label: "Home" },
  { href: "/about", label: "About" },
  { href: "/contact", label: "Contact Us" },
  { href: "/docs", label: "Docs" },
  { href: "/guides", label: "Guides" },
];

export default function NavBar() {
  const { pathname } = useRouter();

  return (
    <nav className="border-b border-purple-100 bg-purple-50/90 px-6 py-4 text-sm font-medium text-purple-950 dark:border-purple-900/60 dark:bg-purple-950/30 dark:text-purple-100">
      <div className="mx-auto flex max-w-6xl flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Link href="/" className="text-base font-semibold tracking-tight">
          AGENTS.md
        </Link>
        <div className="flex flex-wrap gap-2">
          {navLinks.map((link) => {
            const isActive = pathname === link.href;

            return (
              <Link
                key={link.href}
                href={link.href}
                className={`rounded-full px-3 py-1.5 transition hover:bg-white/70 dark:hover:bg-white/10 ${
                  isActive
                    ? "bg-white text-purple-900 shadow-sm dark:bg-white/15 dark:text-white"
                    : "text-purple-800 dark:text-purple-200"
                }`}
              >
                {link.label}
              </Link>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
