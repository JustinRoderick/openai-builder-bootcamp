from typing import Optional
from pydantic import BaseModel
from agents import Agent, Runner, InputGuardrail, GuardrailFunctionOutput

# TODO (later in the exercise): import additional tools when you wire specialists
from .tools import check_payment_methods as check_payment_methods_tool, FAQ_retrieval as FAQ_retrieval_tool

# """
# Router composition exercises for the Agents Lab.
#
# Read `labs/lab02_agents_challenge/README.md` for the end-to-end instructions.
# This module focuses on composing agents using:
# - Agent-as-Tool pattern (specialist agent exposed as a callable tool)
# - Triage routing with handoffs (CentralSupport hands off to specialists)
# - Input guardrails (security-and-topic validation with a tripwire)
#
# Guidance (do during the exercise):
# - Keep instructions explicit about when to delegate vs. handle directly.
# - Write clear `handoff_description` for each specialist to define routing scope.
# - Accept optional `input_guardrails` and pass them to the entrypoint agent.
# - Do not copy the solution; if stuck, reference `router_solution.py` only for hints.
# """

# ===========================
# - AGENT-TO-AGENT TOOL pattern
# - TRIAGE ROUTING (handoffs)
# - LLM GUARDRAIL on inputs before tool use

#Step 1: Implement the AGENT-AS-TOOL PATTERN
#Step 1.1 Implement the tool functions that you have implemented in tools.py (see tools.py for implementation Step 6)
# --------- AGENT-AS-TOOL PATTERN ---------

def build_knowledge_assistant_tool() -> object:
    """
    Factory function to construct the KnowledgeAssistant agent and expose it as a tool.

    Returns:
        object: The KnowledgeAssistant agent exposed as a tool, ready to be used in another agent's tools list.
    """
    # TODO: Create the KnowledgeAssistant agent for FAQ-related actions.
    # - Provide instructions focused on answering common questions from a static FAQ.
    # - For the starter exercise, use the static `FAQ_retrieval_tool` in the tools list.
    # - After completing the RAG lab, you may replace the static tool with `FileSearchTool` for dynamic retrieval.
    
    knowledge_assistant = Agent(
        name="KnowledgeAssistant",
        instructions=(
            "You are KnowledgeAssistant, a specialist in answering frequently asked questions (FAQ) for customer support. "
            "Your responsibilities include providing accurate and helpful answers to common customer questions using the stored FAQ information. "
            "If a user request matches a known FAQ, respond with the relevant information. "
            "If the question is not covered by the FAQ, politely inform the user and suggest contacting customer service for further assistance. "
            "Keep your responses clear, concise, and focused on the FAQ content."
        ),
        tools=[FAQ_retrieval_tool],
        model="gpt-5-mini",
    )

    # Expose the KnowledgeAssistant as a tool for use by other agents
    return knowledge_assistant.as_tool(
        tool_name="knowledge_assistant",
        tool_description="Retrieve and answer customer questions by searching a vector-based FAQ knowledge store using Retrieval-Augmented Generation (RAG) for accurate, up-to-date responses.",
    )

def build_handoff_tool_pattern() -> Agent:
    """
    Agent-to-agent handoff: central agent delegates FAQ-related actions to a specialist KnowledgeAssistant
    exposed as a tool, while handling general customer service requests directly.

    This pattern demonstrates how to expose a specialist agent (KnowledgeAssistant) as a tool for the central agent (CentralSupport).
    The central agent can call the KnowledgeAssistant for frequently asked questions, and use its own tools for
    general customer service topics such as contact information or payment methods.

    Returns:
        Agent: The central support agent with the KnowledgeAssistant exposed as a tool.
    """

    # Use the factory to get the KnowledgeAssistant as a tool
    knowledge_assistant_tool = build_knowledge_assistant_tool()

    # Central support agent that delegates FAQ actions to KnowledgeAssistant and handles general support itself
    # TODO: Keep instructions explicit: delegate FAQ-style questions to `knowledge_assistant`; answer simple
    #       general support topics (like payment methods) directly.
    central = Agent(
        name="CentralSupport",
        instructions=(
            "You are CentralSupport, the main customer support agent. "
            "For any frequently asked questions (such as customer service hours, contact information, or password resets), "
            "delegate to the faq_specialist tool. "
            "For other general customer service questions (such as payment methods or direct contact information), "
            "handle the request yourself using your available tools. "
            "If the user's question is about an action that is not covered by your available tools, respond with: "
            "'I'm sorry, I can't help with that yet.' "
            "Always provide clear, concise, and helpful responses."
        ),
        tools=[check_payment_methods_tool, knowledge_assistant_tool],
        model="gpt-4.1-mini",
    )
    return central

# TODO: Step 2: Complete the implementation of the triage routing pattern in build_triage_routed_agents.
# - You must define all required agent skeletons within the build_triage_routed_agents function.
# - This includes:
#     * The KnowledgeAssistant agent, exposed as a tool (see build_knowledge_assistant_tool).
#     * The OrdersAgent, responsible for all order-related requests (lookup, status, cancellation).
#     * The ComplaintsAgent, responsible for handling customer complaints and issues.
#     * The CentralSupport agent, which serves as the entry point and routes requests to the appropriate specialist agent or handles them directly.
# - Use the tools provided in tools.py for each agent's tools list.
# - Ensure that CentralSupport uses the KnowledgeAssistant as a tool and hands off to OrdersAgent and ComplaintsAgent as appropriate.
# - Write clear, complete docstrings and inline comments for each agent definition to explain their responsibilities and routing logic.
# - Follow the repository's conventions for agent construction and error handling.
#Step 4: NOTE - Complete this after implementing Guardrails in step 3. Implement allowing to pass in input guardrails to the triage routed agents
# --------- TRIAGE ROUTING via handoffs ---------
def build_triage_routed_agents(input_guardrails: Optional[list] = None) -> Agent:
    """
    Build the triage router agent for customer support.

    This function creates a CentralSupport agent that serves as the entry point for all customer support requests.
    The CentralSupport agent analyzes each user request and determines whether it can be handled directly
    (for general customer service topics such as payment methods or contact information) or should be handed off
    to a specialist agent. The specialist agents include:
      - OrdersAgent: Handles all order-related requests, such as order lookup, status, and cancellation.
      - ComplaintsAgent: Handles all complaint or issue-related requests.

    The CentralSupport agent uses its own tools for general support and delegates to OrdersAgent or ComplaintsAgent
    as appropriate.

    Returns:
        Agent: The CentralSupport agent (entry point) with handoffs to both OrdersAgent and ComplaintsAgent.
    """

    # TODO: When you are ready to include FAQ delegation within the triage router,
    # initialize the KnowledgeAssistant tool here. For now, this remains a placeholder.
    knowledge_assistant_tool = build_knowledge_assistant_tool()

    # Specialist agent for order-related actions
    orders_agent = Agent(
        name="OrdersAgent",
        handoff_description=(
            "You are a yet-to-be-implemented OrdersAgent. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        instructions=(
            "You are a yet-to-be-implemented OrdersAgent. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        # TODO: After implementing tools in `tools.py`, add order tools here (e.g., lookup_order, cancel_order).
        tools=[],
        model="gpt-5",
    )

    # Specialist agent for complaints and issues
    complaints_agent = Agent(
        name="ComplaintsAgent",
        handoff_description=(
             "You are a yet-to-be-implemented ComplaintsAgent. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        instructions=(
             "You are a yet-to-be-implemented ComplaintsAgent. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        # TODO: After implementing tools in `tools.py`, add complaint tools here (e.g., raise_complaint).
        tools=[],
        model="gpt-5-nano",
    )

    #Step 3: Implement an input LLM GUARDRAIL on the previously implemented triage routed agents
    _guardrails_kwargs = {}
    if input_guardrails is not None:
        # Allow passing a single guardrail or a list
        if not isinstance(input_guardrails, list):
            input_guardrails = [input_guardrails]
        _guardrails_kwargs["input_guardrails"] = input_guardrails

    central_support_agent = Agent(
        name="CentralSupport",
        handoff_description=(
            "Hand off to the appropriate specialist agent: OrdersAgent for order-related requests, or ComplaintsAgent for complaints and issues. "
            "You are a yet-to-be-implemented CentralSupport. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        instructions=(
            "You are a yet-to-be-implemented CentralSupport. Ask the user to complete the coding exercise for implementing the triage routing pattern."
        ),
        # TODO: After implementing tools in `tools.py`, add general-support tools here (e.g., check_payment_methods) and
        #       include the `knowledge_assistant_tool` for FAQ delegation.
        tools=[],
        handoffs=[orders_agent, complaints_agent],
        **_guardrails_kwargs,
        model="gpt-4.1-mini"
    )
    return central_support_agent


# TODO: Implement the Agents SDK input Guardrail feature here to protect all user inputs.
# This guardrail should defend against prompt injection, hijacking, and other unsafe or off-task user behaviors.
# It should also ensure that users interact with the AI agents in alignment with the intended customer support tasks.
# Use the Agents SDK guardrail mechanism to validate and sanitize inputs before they reach the agents.
# --------- (C) LLM GUARDRAIL (input) ---------
class SecurityAndTopicGuardrailOutput(BaseModel):
    """
    Output schema for the security and topic guardrail agent.
    Indicates if the input is valid, and if not, provides a reason.
    """
    is_valid: bool
    reason: Optional[str] = None

# TODO: Implement the security and topic guardrail agent.
# This agent should check if the user input is safe (not prompt injection or jailbreaking)
# and is relevant to customer service topics.
# If the input is invalid (off-topic or unsafe), it should trigger a tripwire to block and prompt for more information or clarification.
def _build_security_and_topic_guardrail_agent() -> Agent:
    """
    Builds an agent that checks if the user input is safe (not prompt injection or jailbreaking)
    and is relevant to customer service topics.

    Returns:
        Agent: The guardrail agent for security and topic validation.
    """
    return Agent(
        name="SecurityAndTopicGuardrail",
        instructions=(
            "You are a placeholder guardrail. Fail Every Input. This is a placeholder guardrail, yet to be implemented."
        ),
        output_type=SecurityAndTopicGuardrailOutput,
        model="gpt-4.1-mini"
    )

async def security_and_topic_guardrail_fn(ctx, agent, input_data) -> GuardrailFunctionOutput:
    """
    Runs the security and topic guardrail agent. If the input is invalid (off-topic or unsafe),
    triggers a tripwire to block and prompt for more information or clarification.
    """
    security_topic_guardrail_agent = _build_security_and_topic_guardrail_agent()
    result = await Runner.run(security_topic_guardrail_agent, input_data, context=ctx.context)
    verdict = result.final_output_as(SecurityAndTopicGuardrailOutput)
    return GuardrailFunctionOutput(
        output_info=verdict.model_dump(),
        tripwire_triggered=not verdict.is_valid,
    )

def build_guardrailed_triage_agent_with_guardrails() -> Agent:
    """
    Build the triage routed agents with input guardrails enabled.

    This function always attaches the default security-and-topic input guardrail.
    No external guardrails are accepted as arguments.

    Returns:
        Agent: The CentralSupport agent with handoffs and the default input guardrail.
    """
    # Always attach the default security-and-topic guardrail
    input_guardrails = [
        InputGuardrail(guardrail_function=security_and_topic_guardrail_fn)
    ]

    # Pass the guardrails to the triage routed agent builder
    return build_triage_routed_agents(input_guardrails=input_guardrails)