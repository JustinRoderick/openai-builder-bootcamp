# Builder Bootcamp: Plan, Build, and Ship with Codex

### Lab Metadata

- **Lab type**: Guided, hands-on
- **Duration**: ~60 minutes
- **Level**: Advanced builders
- **Environment**: Codex app or Codex CLI, local terminal, Node.js + pnpm
- **Repo path**: `labs/lab05_codex_guided`
- **Last updated:** May 29, 2026

### Overview
In this lab, you will use Codex to plan, build, and deliver real code changes in an existing Next.js repository. You will:
- **Create core collaboration artifacts**, such as `AGENTS.md`, and use plan mode before editing.
- **Use Codex interaction modes** for read-only analysis, plan mode, single-shot execution, and iterative prototyping.
- **Create and use a reusable Skill** for repeatable page-delivery workflows.
- **Validate outputs** with lint/typecheck and manual smoke checks.

This lab is intentionally practical. It is designed to reflect how builders work with Codex agents in production-style repos: defining constraints, using plan mode, reviewing changes, and shipping scoped improvements rapidly.

### Learning Objectives
After completing this lab, you will be able to:

1. Open the lab in either the Codex app or Codex CLI and run the application locally while keeping a terminal available for development commands.
2. Use read-only prompts and plan mode to map the codebase, identify target files, and compare implementation options before editing.
3. Configure repository execution standards with `AGENTS.md` and verify they change how Codex plans and operates.
4. Implement features with single-shot and iterative workflows while keeping diffs scoped and reviewable.
5. Create and apply a reusable skill, then deliver PR-ready outputs with validation (`pnpm lint`, `pnpm typecheck`) and handoff notes.

### Prerequisites
- **Codex surface**: Codex app installed, or Codex CLI available in PATH (`codex --version`)
- **Runtime**: Node.js installed (`node -v`)
- **Package manager**: `pnpm` installed (`pnpm -v`)
- **Authentication**: Workshop-provided OpenAI API key for Codex sign-in
- **Access**: Workshop-provided API key must be active for Codex use
- **Repository**: Local copy of `builder-bootcamp` with access to `labs/lab05_codex_guided`

> **Choose your Codex surface:** Complete this lab in either the Codex app or Codex CLI. The prompts, files changed, and validation steps are shared. Where interaction controls differ, this guide provides both paths.

## Task 1. Set up your environment

> **Tip:** Open this file in Markdown Preview mode for easier scanning during the lab.

In this task, you will verify dependencies, choose your Codex surface, and run the app. The app is a small Next.js microsite used as the working codebase for Codex planning, editing, validation, and handoff workflows.

1. Move into this lab directory:
```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
```

2. Verify Node.js, npm, and pnpm are installed:
```bash
node -v
npm -v
pnpm -v
```

*Expected output:*
```text
v22.10.0
10.9.0
9.15.1
```

If `pnpm` is missing:
```bash
npm i -g npm@latest
npm i -g pnpm@latest
```

3. Choose one Codex surface.

**Codex app track**

- Open the Codex app, choose **Sign in with an API key**, and paste the OpenAI API key provided by your facilitator when prompted.
- Treat this key as a secret: do not paste it into Codex prompts, lab output files, screenshots, or source control.
- Open this folder as the active workspace:

```text
~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
```

**Codex CLI track**

- Install or verify the CLI:

```bash
npm i -g @openai/codex
codex --version
```

- Authenticate with the workshop-provided API key. Run `read -s OPENAI_API_KEY`, paste the key, and press Enter; your input will remain hidden:

```bash
read -s OPENAI_API_KEY
export OPENAI_API_KEY
printenv OPENAI_API_KEY | codex login --with-api-key
unset OPENAI_API_KEY
```

The key must not be saved in the repository or included in lab deliverables.

4. Start the local application using your chosen Codex surface.

**Codex app track**

In your active lab workspace, ask Codex:

```text
Install dependencies if needed, start the local development server for this lab, and open the running application in the in-app browser. Do not edit source files.
```

Approve the terminal action if prompted. Codex should start the development server and open the localhost URL in the in-app browser for preview.

**Codex CLI track**

Keep Codex available in one terminal, and run the application from a second terminal tab or window:

```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
pnpm install
pnpm dev
```

**Checkpoint:** You should see your application load in the Codex in-app browser or your browser (usually on `http://localhost:3000`, or the next available port) and resemble the following:

![Localhost app running](img/localhost.png)

Now that the environment is ready and your application is running, you are ready to explore the repo with read-only Codex prompts before making changes.

## Task 2. Explore the lab files and repo with Codex & plan mode

In this task, you will run read-only prompts to validate that Codex correctly understands the codebase and change surface.

This app is a small Next.js customer-support style microsite that we will extend during the lab. Instead of manually mapping the repo first, you will use Codex to quickly surface architecture, entrypoints, commands, and risk areas before making edits.

Use this translation guide whenever the interaction surface differs:

| Workflow step | Codex app | Codex CLI |
| --- | --- | --- |
| Open the lab | Open this folder as the workspace | Run `codex` from this folder |
| Plan before editing | Turn on Plan mode | Run `/plan` |
| Return to implementation | Turn off Plan mode | Press `Shift+Tab` to leave plan mode |
| Choose a skill | Use the Skills view or picker | Run `/skills` |
| Review implementation changes | Inspect the changed files in the diff view | Run `/diff` after implementation |

1. Open the lab in your chosen Codex surface:

**Codex app**

Confirm this folder is the active workspace:

```text
~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
```

**Codex CLI**

```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
codex
```

2. Run this prompt:
```text
Read-only analysis only (no edits). Explain this repository in 6 bullets:
1) architecture style
2) key entrypoints
3) dev command
4) validation commands
5) likely first feature to build
6) biggest implementation risk
```

**Expected output:** 

```text
• 1. Architecture style: Next.js 16 + React 19 + TypeScript, using the Pages Router (pages/) with mostly presentational section components...
• 2. Key entrypoints: pages/index.tsx (main landing page + GitHub contributor fetch), pages/_app.tsx (global CSS, shared <Head>, analytics)...
• 3. Dev command: pnpm dev (script runs next dev --turbopack; install first with pnpm install)...
• 4. Validation commands: pnpm lint (and, after Task 5, pnpm typecheck / tsc --noEmit)...
• 5. Likely first feature to build: A global navbar + new pages (/about, /contact, /docs) by adding components/NavBar.tsx...
• 6. Biggest implementation risk: Sitewide UI regression when introducing global layout/nav through pages/_app.tsx...
```

Codex should return six concise bullets similar to the above that reference paths and commands. You now have a fast, file-level map of where changes belong and what checks matter before touching code.

Now we'll switch into plan mode and ask for implementation options. Plan mode is for structured pre-implementation thinking (files, order of operations, risks), not direct editing. You will reuse this planning pattern in later implementation tasks.

Some best practices for plan mode:
- State scope and non-goals explicitly.
- Ask for exact files and ordered implementation steps.
- Ask for risk levels and rollback notes for each step.
- Require concrete validation commands in the plan.
- Iterate on plan quality before making edits.

3. Enter plan mode, then run the prompt below.

- **Codex app:** Turn on Plan mode in the composer.
- **Codex CLI:** Run `/plan`.

```text
Add a global navbar and pages for About, Contact, and Docs, list exact files to change and why. Suggest a few different implementation plans.
```

**Expected output:** 

```
# Plan: Global Navbar + About/Contact/Docs Pages (Next.js Pages Router)

  ## Summary

  Add a site-wide navbar rendered from pages/_app.tsx, then create three routes: /about, /contact, and /docs. Keep implementation consistent with existing Tailwind + component style, and validate with lint/typecheck + manual smoke checks.

  ## Current State (Grounded)

  - Routing is Pages Router (pages/), with only pages/index.tsx, pages/_app.tsx, and pages/_document.tsx.
  - Shared UI is in components/.
  - Global styles are in styles/globals.css.
  - No existing navbar component or additional content pages yet.

  ... 

  ### Option 3 (Most Extensible)

  - Files: components/NavBar.tsx, components/SiteLayout.tsx, pages/_app.tsx, pages/about.tsx, pages/contact.tsx, pages/docs/index.tsx, optional styles/globals.css.
  - Approach: add layout wrapper component (SiteLayout) that includes navbar and page container.
  - Pros: strong foundation for future footer/sidebar/theming per page shell.
  - Cons: extra abstraction for current scope.

  ... 
```

Codex should propose multiple implementation paths similar to the above that include exact files, rationale, execution order, and risks/tradeoffs. You now have a concrete, reviewable implementation plan before starting edits.

4. After reviewing the plan output, return to the standard prompt without implementing the navbar yet. You will implement it after defining repository guidance and validation expectations in the next tasks.

- **Codex app:** If Codex offers to implement the plan, decline or exit the implementation step for now and turn Plan mode off.
- **Codex CLI:** Press `Shift+Tab` to toggle out of Plan mode.

You should now be back at the standard prompt (not in plan mode), ready to continue to the next task.

**Checkpoint:** You should now have both outputs captured:
- a 6-bullet read-only repository map
- a plan-mode implementation proposal with file-level steps and tradeoffs

With a baseline understanding of the codebase and planning commands, you are now ready to define repository-level execution rules.

## Task 3. Create repository guidance (`AGENTS.md`)

`AGENTS.md` is a repo-level instruction contract that Codex uses to understand how work should be done in this codebase. It defines preferred commands, boundaries, and quality gates so Codex outputs are grounded in your team workflow instead of generic defaults. This is one of the highest-leverage setup steps you can take since it directly improves planning quality and implementation reliability.

Some best practices for building `AGENTS.md` files:
- Keep instructions repo-specific rather than generic, so Codex can anchor plans and edits to your actual project structure and workflows.
- Include both positive instructions (what to do) and explicit guardrails (what to avoid), so behavior is predictable during implementation.
- Define done criteria that are objectively checkable (for example, named validation commands and required handoff artifacts), so completion is not ambiguous.
- Keep the document concise and operational, so it is easy to maintain and easy for Codex to follow consistently.

This lab starts without an `AGENTS.md` file. You will now use Codex to create it with concrete repo instructions that Codex can apply in every later task.

1. In your active Codex app workspace or CLI session, run this implementation prompt:

```text
Create an AGENTS.md file in the current lab directory. Do not edit any other files.

Include these sections and rules:
- Project summary: this is a small Next.js Pages Router site for Codex collaboration exercises; optimize for small, reviewable diffs and fast dev-server iteration.
- Key entrypoints: pages/index.tsx, pages/_app.tsx, components/, styles/globals.css.
- Dev workflow: pnpm install and pnpm dev.
- Validation workflow: pnpm lint and pnpm typecheck.
- Agent guardrails: use the dev server for iterative changes; do not run pnpm build during interactive agent sessions; keep diffs small and scoped; update the lockfile and restart the dev server if dependencies change.
- Definition of Done: pnpm lint and pnpm typecheck pass; manual smoke checks are documented; PR summary and test plan are ready.

After editing, summarize the file you changed.
```

2. Review the new artifact before continuing.

- **Codex app:** Open the changed-files or diff view and inspect `AGENTS.md`.
- **Codex CLI:** Run `/diff` and inspect `AGENTS.md`.

**Checkpoint:** You should see the sections `Project summary`, `Key entrypoints`, `Dev workflow`, `Validation workflow`, `Agent guardrails`, and `Definition of Done`.

Now let's verify that `AGENTS.md` shapes an ordinary task prompt without needing to be named in the request.

3. Continue in your Codex surface.

- **Codex app:** Continue in the active lab workspace.
- **Codex CLI:** Start or return to a Codex session from the lab directory:

```bash
codex
```

4. Run this prompt:
```text
Propose a plan to add a /guides page.
```

**Expected output:** The plan should incorporate repository-specific paths, workflow constraints, validation commands, and done criteria from your `AGENTS.md`. For example:

```bash
• 1. Confirm scope for /guides: static landing page vs. list of guide items (title, summary, link, tags).
  2. Inspect existing patterns in pages/index.tsx, pages/_app.tsx, components/, and styles/globals.css so /guides matches current layout/navigation.
  3. Create pages/guides.tsx with a simple, typed structure:
      - page heading + intro
      - guide list/grid (start with hardcoded data for small diff)
      - basic SEO tags via next/head
  4. Add minimal reusable UI only if needed (for example components/GuideCard.tsx) and keep styling scoped/small.
  5. Add an entry point to reach /guides (home page link or shared nav, depending on current app pattern).
  6. Validate with pnpm lint and pnpm typecheck, then run a quick manual smoke check in pnpm dev (/ and /guides load, links work, mobile layout looks sane).
  7. Prepare PR notes: what changed, why, and test plan/results.
```

5. Identify at least two rules from `AGENTS.md` that appeared in the plan even though the prompt did not mention the file.

**Checkpoint:** You created `AGENTS.md` and verified that Codex automatically uses its repo-specific guidance for work in this lab.

Now that repository guidance is both defined and validated, you will verify the workspace and review behavior that protect later implementation work.

## Task 4. Confirm workspace and review behavior

Before asking Codex to implement a feature, confirm that it is grounded in the correct lab folder and that you can inspect the changes it produces before accepting the result or committing them. This habit matters across both the Codex app and CLI.

1. Confirm the active lab location.

- **Codex app:** Confirm the active workspace is:

```text
~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
```

- **Codex CLI:** Confirm you started `codex` from:

```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
```

2. Ask Codex this read-only check:

```text
Propose a plan to add a /resources page in this repo. Include the repo rules and validation steps you will follow. Do not edit files.
```

**Expected output:** Codex should reflect the key entrypoints, dev workflow, validation workflow, guardrails, and definition of done from `AGENTS.md`, without the prompt explicitly pointing it to that file.

3. After later implementation prompts, inspect the changed files before accepting results or committing them.

- **Codex app:** Use the changed-files or diff view after edits are made.
- **Codex CLI:** Run `/diff` after implementation and before committing.

**Checkpoint:** You confirmed the active repo, verified that `AGENTS.md` guidance affects planning, and know how to review changes after implementation.

> **Advanced note:** Configuration is intentionally outside the required lab path. Current Codex documentation supports selected project-local `.codex/config.toml` settings, but configuration profiles are user-level configuration and are not a project-local lab artifact. See the [Codex configuration reference](https://developers.openai.com/codex/config-reference#configtoml).

With repository guidance and review behavior established, you will now wire the validation command used by later tasks.

## Task 5. Add a `typecheck` script

Adding a `typecheck` script creates a single, reusable TypeScript validation command for this repository. In this lab, it becomes part of your quality contract: `AGENTS.md`, Codex plans, and final validation should all point to the same command.

Some best practices for script-based validation:
- Keep script names action-oriented and consistent across docs and prompts.
- Use `tsc --noEmit` for fast type validation without producing build artifacts.
- Keep validation commands centralized in `package.json` so humans and agents run the same checks.
- Verify the script exists before relying on it in plans or done criteria.

1. Ask Codex to make this focused validation change:

```text
Add a reusable typecheck script to package.json:
"typecheck": "tsc --noEmit"

Keep the edit limited to package.json. After making the change, run pnpm typecheck and summarize the result.
```

**Expected scripts shape:**

```json
"scripts": {
  "dev": "next dev --turbopack",
  "build": "next build",
  "start": "next start",
  "lint": "eslint .",
  "typecheck": "tsc --noEmit"
}
```

2. Inspect Codex's diff before continuing.

- **Codex app:** Confirm the changed-files view shows only the new `package.json` script.
- **Codex CLI:** Run `/diff` and confirm only the intended script was added.

3. Ask Codex to exercise the validation command and clean up after itself:

```text
Validate the new typecheck script by temporarily adding one obvious TypeScript type mismatch in pages/index.tsx, running pnpm typecheck to show that it fails, then removing the temporary mismatch and running pnpm typecheck again to show that it passes. Leave no temporary drill change in pages/index.tsx when you finish.
```

**Expected output:** During the drill, TypeScript reports an error similar to the following:

![Typecheck error example output](img/typecheck-error-example.png)

After Codex removes the temporary mismatch, the final validation run should succeed:

```bash
> agents.md@0.1.0 typecheck /Users/slubbers/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
> tsc --noEmit
```

4. Review the final diff and confirm that the temporary mismatch is gone. Only the intended `package.json` script should remain from this task.

5. Now validate that Codex incorporates this command in its recommendations. Enter plan mode and run:

- **Codex app:** Turn on Plan mode.
- **Codex CLI:** Run `/plan`.

Then run this prompt:
```text
Before shipping a navbar + new pages change in this repo, what validation commands should we run?
```

**Expected output:** 

```bash
Run these before shipping:

  pnpm lint
  pnpm typecheck

  For this specific navbar + pages change, also do a quick manual smoke check via:

  pnpm dev

  Then verify navigation works and each new page loads correctly in the browser.
```

**Checkpoint:** You added `typecheck`, verified it exists, optionally watched it catch a real mismatch, and confirmed Codex references it in validation guidance.

Now that validation commands are standardized, move into your first implementation cycle.

## Task 6. Single-shot implementation cycle

In this task, you will execute one scoped feature using a single implementation prompt. This is the fastest Codex workflow when requirements are clear and bounded, and it is a good baseline pattern before moving into deeper multi-step iteration.

Some best practices for single-shot implementation:
- State exact deliverables and constraints in one prompt.
- Require explicit output format (files changed, assumptions, validation run).
- Keep diffs scoped and avoid unrelated refactors.
- Validate immediately after applying the patch.

> 💡 **Hypothetical scenario:** Imagine your product manager or design team hands you the requirements below and asks for a fast, high-quality implementation. You will use Codex to implement that scoped request end-to-end:
>
> - *Add a global navbar visible on all pages.*
> - *Add:*
>   - *`components/NavBar.tsx`*
>   - *`pages/about.tsx`*
>   - *`pages/contact.tsx`*
>   - *`pages/docs/index.tsx`*
> - *Navbar links: Home, About, Contact Us, Docs.*
> - *Each page includes one `<h1>` and 2-4 short paragraphs.*
> - *Layout remains usable on narrow screens.*
> - *Ensure the navbar is set to a soft purple color.*

1. Return to your Codex surface with Plan mode turned off.

- **Codex app:** Confirm the active workspace is this lab folder.
- **Codex CLI:** Start Codex from the lab directory if it is not already running:

```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
codex
```

2. Run this prompt in Codex:
```text
Implement the feature below in this Next.js Pages Router repo.

Feature:
- Global navbar on all pages
- Pages: /about, /contact, /docs
- Navbar links: Home, About, Contact Us, Docs
- Each page has one H1 and 2-4 short paragraphs
- Keep styling consistent with existing repo patterns
- Keep diffs focused and avoid unrelated changes
- Ensure the navbar is set to a soft purple color.

After implementation, return:
1) files changed
2) assumptions
3) exact validation commands run
4) manual smoke checklist
```

3. Let Codex run. This may take a couple minutes.

Let Codex complete the implementation, then inspect its diff. In the app, review the changed files; in the CLI, run `/diff`. If the result is out of scope, ask Codex to correct or revert its changes before proceeding.

4. Once the implementation completes, validate and smoke-test using your chosen Codex surface.

**Codex app**

Ask Codex:

```text
Validate the navbar and new pages work: run pnpm lint and pnpm typecheck, then open the running local app in the in-app browser and check /, /about, /contact, and /docs. Report validation results and any visible issues. Do not make additional edits unless I ask.
```

**Codex CLI**

Run validation in your terminal:

```bash
pnpm lint
pnpm typecheck
```

```bash
pnpm dev
```

Open the localhost URL shown by `pnpm dev` (often `http://localhost:3000`) and verify `/`, `/about`, `/contact`, and `/docs`.

**Expected output:** `pnpm lint` and `pnpm typecheck` complete successfully with no errors, and you see the navbar with links for Home, About, Contact Us, and Docs.

**Expected output:**

![Task 6 expected navbar and routes](img/task6-navbar-expected.png)

5. Confirm each navbar link works and `/`, `/about`, `/contact`, and `/docs` all load correctly.

**Checkpoint:** Feature is implemented, validation passes, navbar is visible, and all four routes load correctly from the navigation links.

With the single-shot pass complete, move to a reusable skill workflow for a repeatable implementation pattern.

## Task 7. Build and use a reusable Skill

A Skill is a reusable instruction package for recurring workflows. In this lab, you will build one skill and immediately use it to add a new page end-to-end.

Some best practices for skill authoring:
- Keep scope narrow and explicit.
- Define inputs the skill expects.
- Require validation commands and handoff output shape.
- Keep instructions operational and repo-specific.

1. In your Codex surface, ask Codex to create the skill artifact:

```text
Create `.agents/skills/add_new_page/SKILL.md` in the current lab directory with the following content. Do not edit any application source files yet.

---
name: add-new-page
description: Add a new page in this repo with navbar integration, validation, and handoff output.
---

# Skill: Add a new page end-to-end

## Purpose
Implement a new route/page in this Next.js repo with consistent UX and navigation.

## When to use
When a request requires adding a page and linking it in the navbar.

## Inputs
- page name
- route path
- navbar label
- content requirements
- acceptance criteria

## Workflow
1. Confirm scope/non-goals in 3 bullets.
2. List exact files to edit before coding.
3. Implement the smallest viable diff.
4. Run `pnpm lint` and `pnpm typecheck`.
5. Return required handoff output.

## Required outputs
- files changed
- assumptions
- validation summary
- manual smoke checklist
- residual risks
```

2. Inspect the new skill file in Codex before invoking it.

- **Codex app:** Review `.agents/skills/add_new_page/SKILL.md` in the changed-files or diff view.
- **Codex CLI:** Run `/diff` and review the new skill file.

**Expected output:** You should see frontmatter plus sections for `Purpose`, `When to use`, `Inputs`, `Workflow`, and `Required outputs`.

3. Continue in your Codex surface in the lab directory.

- **Codex app:** Continue in the active lab workspace.
- **Codex CLI:** Start Codex from the lab directory if it is not already running:

```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
codex
```

4. Select the new skill.

- **Codex app:** Open the Skills view or picker, confirm `add-new-page` appears, and select it.
- **Codex CLI:** Run `/skills`, confirm `add-new-page` appears, and select it.

5. In the same Codex session, invoke the skill with a concrete task brief:
```text
$add-new-page

Implement a new Guides page at /guides and add it to the navbar.

Requirements:
- H1 Guides
- section "How to write a good AGENTS.md" (3-5 bullets)
- section "What matters in this repo" with real paths/commands
- links to /docs and /

Return:
1) files changed
2) assumptions
3) validation summary
4) manual smoke checklist
5) residual risks
```

**Expected output:** Codex returns a scoped implementation that follows the skill contract and includes the required handoff outputs.

6. Let Codex run, then inspect the diff and correct any changes that do not match the skill contract before validation.

7. Validate and preview the new page using your chosen surface.

**Codex app**

Ask Codex:

```text
Validate the Guides page produced through the skill: run pnpm lint and pnpm typecheck, then open /guides in the in-app browser and confirm the page renders and the navbar includes Guides. Report the results without making additional edits.
```

**Codex CLI**

```bash
pnpm lint
pnpm typecheck
```

8. For the CLI path, open the localhost URL shown by `pnpm dev` (often `http://localhost:3000`) and verify `/guides` renders and the navbar includes `Guides`.

**Checkpoint:** Skill file is created, `/guides` is implemented through the skill workflow, and validation passes (`pnpm lint` and `pnpm typecheck`).

This completes the core lab path. Continue only if you have time for an open-ended extension.

## Optional Stretch Exercise: Standalone Interactive Prototype

If time remains after completing the core lab, this interactive stretch exercise shows how Codex handles an ambitious feature ask. The goal is not a production game; the goal is a working prototype and one disciplined improvement iteration.

Unlike Task 6 and Task 7, this stretch task should be isolated from the main lab app. You will ask Codex to build a standalone prototype in a separate folder so you can experiment freely without breaking the core Next.js site used in earlier tasks.

Some best practices for interactive prototyping with Codex:
- Keep the prototype isolated from your main application code.
- Start with a minimal, runnable first pass.
- Iterate one improvement at a time and verify each step.
- Ask for explicit run instructions and known limitations in every pass.
- Require Codex to avoid modifying existing `pages/`, `components/`, and the lab app `package.json`.

1. Return to your Codex surface in the lab directory. CLI participants can start a session with:
```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
codex
```

2. Run this starting prompt in Codex:
```text
Build a minimal Three.js flight-simulator prototype as a standalone app inside this repo.
Create it in a new folder at `standalone/flight-sim` (relative to the current lab directory).
Use this concept: take off from an airport and fly around a simplified San Francisco Bay area map.
Reference examples: https://threejs.org/examples/

First pass constraints:
- keep it minimal and runnable in this repo
- implement as a standalone prototype with its own run flow
- add basic controls only
- keep diffs scoped to this feature
- do not modify the existing lab app (`pages/`, `components/`, `styles/`, or the lab root `package.json`)
- include brief in-page instructions for controls
- prefer a simple standalone app setup that I can run locally from `standalone/flight-sim`

Return:
1) files changed
2) run instructions
3) known limitations
```

3. Let Codex run, inspect its diff, and correct or revert any changes outside `standalone/flight-sim` before proceeding.

**Expected output:** A minimal standalone interactive prototype is added under `standalone/flight-sim` with clear run instructions and known limitations.

4. Follow the run instructions Codex returns for the standalone app. In many cases this will look like:
```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided/standalone/flight-sim
pnpm install
pnpm dev
```

If Codex creates a static (no-build) prototype instead, use the exact local run command it provides and continue with the same validation checks below.

5. Open the standalone prototype in the browser and verify:
- the standalone app loads from the URL shown by the prototype dev server
- scene renders without runtime errors
- basic controls respond
- in-page control instructions are visible

6. Verify the first-pass prototype is working and capture a screenshot for your handoff notes.

Open the standalone prototype in the browser and confirm:
- the scene loads
- controls respond
- in-page instructions are visible
- no immediate runtime errors appear in the browser console

**Placeholder screenshot (replace after your run):**

![Task 8 standalone prototype screenshot](img/flight-simulator.png)

7. Test the implementation boundary and confirm the main lab app was not modified by this stretch task (scope check):
```bash
cd ~/Documents/GitHub/builder-bootcamp/labs/lab05_codex_guided
git diff --name-only
```

Verify the new changes for this task are isolated to `labs/lab05_codex_guided/standalone/flight-sim` (and any files Codex explicitly told you it created for the standalone prototype).

8. Get creative: ask Codex to improve the prototype with one or more targeted changes.

Use one prompt at a time, keep the changes scoped, and require Codex to stay inside `standalone/flight-sim`.

Example prompt ideas (pick one):

```text
Improve the standalone flight prototype with a vaporwave visual style.

Constraints:
- Keep all changes inside `standalone/flight-sim`
- Do not modify the main lab app
- Keep controls working

Ideas:
- neon / synthwave color palette
- gradient skybox or background
- simple HUD styling refresh

Return:
1) files changed
2) what changed visually
3) known limitations
```

```text
Improve the standalone flight prototype controls and feel.

Constraints:
- Keep all changes inside `standalone/flight-sim`
- Do not rewrite the app from scratch
- Keep diffs focused

Ideas:
- smoother turn response
- speed boost / brake
- reset position key
- clearer on-screen controls help

Return:
1) files changed
2) what changed in controls
3) how to test it
4) remaining limitations
```

```text
Add a lightweight HUD and gameplay feedback to the standalone flight prototype.

Constraints:
- Keep all changes inside `standalone/flight-sim`
- Keep it minimal and readable

Ideas:
- speed + altitude display
- heading indicator
- crash / out-of-bounds message
- restart button

Return:
1) files changed
2) what was added
3) test steps
4) remaining limitations
```

9. Apply one creative iteration, refresh the standalone prototype, and test the update:
- verify the new behavior/style works as described
- confirm the prototype still runs locally
- re-run the scope check (`git diff --name-only`) if the patch was large

**Checkpoint:** You produced one working standalone interactive prototype, documented a first-pass result, confirmed the main lab app stayed isolated, and completed at least one creative follow-up iteration with clear outputs and testing.

If you have additional time, repeat Step 8 with a different theme or mechanic (visual polish, controls, HUD, environment, or sound) and validate after each pass.

## Conclusion

### Wrap-Up
In this lab, you completed an end-to-end Codex-assisted development workflow suitable for real-world repository collaboration:
1. Worked in either the Codex app or Codex CLI, using the app's local workflow or terminal commands to run and verify local development.
2. Used read-only and plan-mode prompts to map architecture, entrypoints, risks, and implementation options.
3. Established a repo execution contract with `AGENTS.md` and practiced reviewing implementation changes before accepting results.
4. Added and validated a shared `typecheck` command (`tsc --noEmit`) for repeatable quality checks.
5. Implemented a scoped product/design request using a single-shot Codex execution cycle.
6. Built and used a reusable skill (`add-new-page`) to ship a new `/guides` route with validation and handoff output.

If you completed the optional stretch exercise, you also ran an interactive Three.js prototype iteration without destabilizing the main lab app.

### Discussion Prompts
- Operational adoption: Which parts of this workflow are safe to standardize across your team immediately, and which still require review gates?
- Execution strategy: Where should your team prefer single-shot execution vs plan-first decomposition?
- Skill strategy: Which parts of `add-new-page` should remain repo-specific, and which should become reusable templates?

### Troubleshooting
- `pnpm` not found:
  - Cause: pnpm not installed globally.
  - Fix: `npm i -g pnpm@latest`, then verify with `pnpm -v`.
- `codex` not found:
  - Cause: CLI-track participant does not have the CLI installed or on PATH.
  - Fix: `npm i -g @openai/codex`, then rerun `codex --version`, or switch to the Codex app track.
- Authentication issues:
  - Cause: the workshop-provided API key was entered incorrectly, expired, or is unavailable in the selected Codex surface.
  - Fix: in the Codex app, choose **Sign in with an API key** and re-enter the provided key; in the CLI, rerun the `codex login --with-api-key` steps from Task 1. Ask a facilitator for a replacement key if it still fails.
- Skill not available:
  - Cause: `SKILL.md` path is wrong or file/frontmatter is malformed.
  - Fix: verify path at `.agents/skills/add_new_page/SKILL.md`, then refresh the Skills view in the app or rerun `/skills` in the CLI.
- Dev server not accessible:
  - Cause: server stopped, port conflict, or wrong working directory.
  - Fix: rerun `pnpm dev` from `labs/lab05_codex_guided`, then open `http://localhost:3000`.
- `pnpm lint` fails:
  - Cause: dependencies are not installed or an implementation introduces an ESLint error.
  - Fix: run `pnpm install`, correct the reported issue, then rerun `pnpm lint`.
- Lint/typecheck errors after applying changes:
  - Cause: implementation regressions or temporary drill code not removed.
  - Fix: fix reported lines, remove intentional test errors, and rerun `pnpm lint` and `pnpm typecheck`.
- Optional standalone prototype accidentally modifies the main lab app:
  - Cause: the stretch prompt scope was too broad or Codex ignored isolation constraints.
  - Fix: inspect the diff, revert any out-of-bound changes, restate the isolation boundary (`standalone/flight-sim` only), and rerun the prompt with stricter file-scope language.

<!--
## Task 9. Multi-step implementation cycle (deferred for SA review)

> 🚧 This section is intentionally parked for a working session with Charlie.  
> We will decide whether/how a dedicated multi-step workflow should appear in the final v1 guided lab.

If you want a preview direction, use this optional draft prompt:
```text
Build a 4-step implementation plan for this improvement:
[YOUR IMPROVEMENT]

For each step include:
- exact files
- risk level (low/medium/high)
- validation commands
- rollback note if step fails
```
-->
