import React from "react";
import Head from "next/head";

import Footer from "@/components/Footer";

export default function DocsPage() {
  return (
    <div className="flex min-h-screen flex-col font-sans">
      <Head>
        <title>Docs | AGENTS.md</title>
      </Head>
      <main className="flex-1 px-6 py-16">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-4xl font-semibold tracking-tight">Docs</h1>
          <div className="mt-6 space-y-4 text-lg leading-relaxed text-gray-700 dark:text-gray-300">
            <p>
              Start with a short AGENTS.md file at the root of your repository so agents can find instructions before making changes.
            </p>
            <p>
              Include the project summary, key entrypoints, development workflow, validation commands, and any guardrails that matter for safe edits.
            </p>
            <p>
              Keep the file current as your project changes, especially when dependencies, testing expectations, or release workflows evolve.
            </p>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
