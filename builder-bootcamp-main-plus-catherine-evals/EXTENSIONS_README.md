# Extension Exercises

**Finished already? That was quick!**

If you are hungry for more practice, consider how you would approach some of the following open questions. You can ask the facilitators for advice if you get stuck.

## Advanced RAG Questions
There are many situations where the standard procedure of chunking + vectorising documents does not yield good retrieval results. Below are several common failure cases; think about why vector retrieval might not work in these cases and how you might design a solution.


### Questions
1) Matching based on a specific Key or entity name
   * "Which support tickets were filed by Jane Q. Customer?"
   * "What is the status of case `CS-1234`?"
2) When the wording of a question substantially differs from the document content
   * "Why is my bill higher this month?"
     * Document content: _"Invoice and usage summary for September 2025..."_
   * "How do I get a refund on an item I bought online?"
     * Document content: _"Returns are processed via the RMA portal. Initiate a return within 30 days and include your order number to generate a prepaid label."_
3) When a question cannot be answered by a single chunk
   * "What were the main root causes for delayed orders in our South Ayrshire stores last month?"
   * "How is warranty coverage handled for Premium Plan devices after 12 months?"


### Hints
1) Vector search matches based on **semantic** similarity of the query as a whole, meaning high-signal tokens (ABC-1234) are not necessarily attended to.
   * Traditional techniques like TF/IDF or BM25 combine vector search with the presence of specific keywords.
   * In some cases, key:value stores or structured search may be a better fit than vectorisation
2) When designing a retrieval system, it's important to look at real samples of how users query data. It is often necessary to pre-process both queries and source data to make sure they match more closely:
   * Query pre-processing is the act of rewriting and expanding user queries - expanding any acronyms and looking up industry-specific terms in a glossary; sending multiple queries in parallel using different rewordings of the same question, etc.
   * Hypothetical Document Embedding (HyDE) is a technique where the user query is rewritten by a language model into a hypothetical answer that is likely to be semantically similar to the source data, e.g.:
     * Query: “Why is my bill higher this month?”
     * HyDE-generated hypothetical passage: _“Your invoice increased due to proration from a mid-cycle plan change, overage SMS charges, and an expired promotional credit.”_
     * The embedding of this passage is then used to search the vector store, improving the chance of matching documents that talk about proration, overage charges, and promotions — even if the original query didn’t use those words.
   * Other document processing techniques prove useful when using vector search, such as converting structured tables into markdown or XML formats where the column headings are colocated near the row content
3) Often retrieval is discussed in the context of a single call-response model. However, in some cases it makes more sense to consider retrieval a _system_ consisting of multiple parts:
   * Agentic approaches to retrieval may provide an agent with a set of retrieval tools, metadata about the available documents and what information they contain, or a plan of action for how to query complex and distributed data sources.
   * Knowledge Graphs and other semantic and hierarchical data structures can be used to establish relationships between entities and concepts, enabling the system to traverse connections, summarize information from multiple documents, and synthesize complex answers that would otherwise be missed if only looking at individual chunks in isolation.

## Advanced Agent Questions

Agentic systems in the real world are substantially more complex than single "tool + reply" demos. Below are several recurring challenges; consider the failure modes and how you would engineer robust, observable, and governable systems.


### Questions
1) Architecting networks of agents at scale
   * "How do we avoid duplicated prompts/tools/guardrails across teams and keep versions consistent?"
   * "How do agents discover existing capabilities and share them safely across org boundaries?"
2) Monitoring and auditability
   * "How do we log inputs/outputs, tool calls, and decisions for audit while protecting PII?"
   * "How do we detect system drift and upgrade or roll back safely?"
3) Reliability, safety, and cost/latency governance
   * "How do we bound tool loops, enforce budgets/SLAs, and handle retries/timeouts gracefully?"


### Hints
1) Treat prompts, tools, and policies as first-class, versioned assets
   * Consider establishing a central registry for prompts, tools, and guardrails, with clear ownership, versioning and lifecycle events e.g. deprecation
   * Investigate the 'MCP' protocol as a means to make tools consistently discoverable and remotely callable
2) Consider observability and governance as a first-order priority
   * Configure end-to-end tracing and structured logs for LLM calls, tool steps, and planner decisions.
   * Ensure conversations are stored in a privacy-aware way with access controls and retention policies.
   * One-time evals are not sufficient - configure ongoing monitoring to detect behavioural drift once a system is in production
   * For high-impact customer-facing systems, implement automated alerting, clearly defined upgrade/rollback procedures, and playbooks for rapid incident response.
3) Engineer systems to prioritize reliability, safety, and efficiency.
   * Centrally monitor token consumption + spend, tagged against API keys, projects or internal metadata to keep track of budgets and limits
   * Use timeouts, retry rules and circuit breakers to keep system behavior within safe boundaries and prevent failures from spreading.
   * Design tools according to the principle of least-privilege and introduce policy controls or approval gates for actions that carry higher risks, e.g. write operations on user data

