import React from "react";
import Head from "next/head";

import Footer from "@/components/Footer";

export default function ContactPage() {
  return (
    <div className="flex min-h-screen flex-col font-sans">
      <Head>
        <title>Contact Us | AGENTS.md</title>
      </Head>
      <main className="flex-1 px-6 py-16">
        <div className="mx-auto max-w-3xl">
          <h1 className="text-4xl font-semibold tracking-tight">Contact Us</h1>
          <div className="mt-6 space-y-4 text-lg leading-relaxed text-gray-700 dark:text-gray-300">
            <p>
              The best way to get involved is through the AGENTS.md project repository and the conversations happening around open agent guidance.
            </p>
            <p>
              Share examples, suggest improvements, or ask questions where maintainers and contributors can review them in the open.
            </p>
            <p>
              For policy and project ownership details, refer to the Linux Foundation project links in the footer.
            </p>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
