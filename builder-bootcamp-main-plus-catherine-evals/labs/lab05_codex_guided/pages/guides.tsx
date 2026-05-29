import React from "react";
import Head from "next/head";
import Link from "next/link";

import Footer from "@/components/Footer";

export default function GuidesPage() {
  return (
    <div className="flex min-h-screen flex-col font-sans">
      <Head>
        <title>Guides | AGENTS.md</title>
      </Head>
      <main className="flex-1 px-6 py-16">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-4xl font-semibold tracking-tight">Guides</h1>

          <section className="mt-8">
            <h2 className="text-2xl font-semibold tracking-tight">
              How to write a good AGENTS.md
            </h2>
            <ul className="mt-4 list-disc space-y-3 pl-6 text-lg leading-relaxed text-gray-700 dark:text-gray-300">
              <li>Start with a short project summary and the main user-facing purpose.</li>
              <li>Name the files and folders agents should inspect before changing code.</li>
              <li>Document the exact install, dev server, lint, and typecheck commands.</li>
              <li>Call out guardrails, non-goals, and review expectations for safer diffs.</li>
            </ul>
          </section>

          <section className="mt-10">
            <h2 className="text-2xl font-semibold tracking-tight">
              What matters in this repo
            </h2>
            <div className="mt-4 space-y-4 text-lg leading-relaxed text-gray-700 dark:text-gray-300">
              <p>
                The core route files live in <code>pages/index.tsx</code>,{" "}
                <code>pages/_app.tsx</code>, and the other files under{" "}
                <code>pages/</code>.
              </p>
              <p>
                Shared UI belongs in <code>components/</code>, with global styling
                in <code>styles/globals.css</code>.
              </p>
              <p>
                Use <code>pnpm dev</code> for local iteration, then validate with{" "}
                <code>pnpm lint</code> and <code>pnpm typecheck</code>.
              </p>
            </div>
          </section>

          <div className="mt-10 flex flex-wrap gap-3 text-sm font-medium">
            <Link
              href="/docs"
              className="rounded-full bg-purple-100 px-4 py-2 text-purple-900 transition hover:bg-purple-200 dark:bg-purple-900/50 dark:text-purple-100 dark:hover:bg-purple-900"
            >
              Read the docs
            </Link>
            <Link
              href="/"
              className="rounded-full bg-gray-100 px-4 py-2 text-gray-900 transition hover:bg-gray-200 dark:bg-white/10 dark:text-white dark:hover:bg-white/15"
            >
              Back home
            </Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
