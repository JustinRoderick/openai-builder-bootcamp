import React from "react";
import Head from "next/head";

import Footer from "@/components/Footer";

export default function AboutPage() {
  return (
    <div className="flex min-h-screen flex-col font-sans">
      <Head>
        <title>About | AGENTS.md</title>
      </Head>
      <main className="flex-1 px-6 py-16">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-4xl font-semibold tracking-tight">About AGENTS.md</h1>
          <div className="mt-6 space-y-4 text-lg leading-relaxed text-gray-700 dark:text-gray-300">
            <p>
              AGENTS.md is a simple convention for giving coding agents the project context they need before they edit code.
            </p>
            <p>
              This site introduces the format, shows how teams use it, and keeps the guidance easy to scan during everyday development.
            </p>
            <p>
              The goal is practical collaboration: fewer repeated explanations, smaller diffs, and clearer handoffs between people and agents.
            </p>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
