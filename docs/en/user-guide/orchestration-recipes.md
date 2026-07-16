---
title: "From Goal to Plan: Orchestration Recipes"
sync:
  source_commit: manual-authored
  generated_by: playbook v4 (orchestration layer)
---

# From Goal to Plan: Orchestration Recipes

Earlier chapters teach you to use **individual features** (creating an Agent, chatting, publishing an app…). But what's in your head is usually a **goal**, not a feature — like "I want AI to run a set of checks on my server and produce a report," or "I want an assistant that keeps watching some data and alerts me when something happens."

This chapter teaches a way of thinking: **break a goal into a combination of "what to prepare first, then which capabilities to use in what order."** When you're not sure where to start, come back here — or just ask the [Manual Assistant](../index.md#手册助手), which follows these recipes to give you a path from goal to reality.

::: tip How to use this chapter
No need to read top to bottom. Find the recipe closest to your goal and follow it; if your goal is a variation, adapt it. Each recipe lists "which chapters it depends on" — click through for the concrete steps.
:::

## Think through three things first

When you have a goal, ask yourself:

1. **What kind of Agent do you need?** Is a general assistant enough, or do you need a domain expert with specialized tools?
2. **Where and on what will it work?** Just answer questions in chat, or operate on your files, your servers, your business data?
3. **What's the deliverable?** A reply, a report file, a shareable web app, or a task that runs automatically on a schedule?

Answer these three, and the recipes below fall into place.

## Recipe 1: Have an Agent run a task on a server and produce a report

**Typical goals**:
- "Run a security check on a specified internal app and generate a report" (authorized security testing, compliance inspection)
- "Periodically log into a server, collect logs, analyze anomalies, and compile a report"
- "Set up an environment on a test box per my steps and run a verification suite"

::: warning Authorization prerequisite
Any "log into a server and operate" task — especially security testing, penetration testing, vulnerability scanning — **may only be done on systems you own or have written authorization for**. Confirm your scope beforehand and tell the Agent that scope as a constraint (see Step 3). Probing unauthorized systems is illegal in many jurisdictions, and the platform does not support it.
:::

**Orchestration path**:

1. **Build a domain-expert Agent**. Use [Creating an Agent](./create-agent.md) with a clear request — e.g. "a security-testing assistant that runs standard security checks on my authorized web apps (config review, common weakness checks) and compiles a structured report to industry standards." Spell out its **scope** and the **report format** you want; the platform designs the workflow and configures suitable tools automatically.
2. **Connect the Agent to the target server**. Use **Bridge** (see [Connecting a Server to Run Tasks](./bridge-server.md)) to establish a connection. When the server is on a private network or behind a firewall, the connection always originates from the server back to the platform — no inbound ports to open.
3. **Set constraints for the Agent**. In the connection and the chat, tell it explicitly: operate only on authorized targets, which tools/commands are allowed, which dangerous actions are forbidden, and to pause and ask you before high-risk operations. Bridge also offers command rules as a backstop.
4. **Drive execution through chat**. In [Chat](./chat.md), have the Agent execute step by step: it runs checks on the server through Bridge under your constraints, with the process visible and [stoppable](./chat.md#停止生成) anytime.
5. **Produce the report**. Ask it to compile the results into a report saved to the conversation's workspace; download it from [file management](./chat.md).
6. **(Optional) Save for reuse**. Package this Agent into an app with [Publish Your First App](./publish-first-app.md), or save its check process as a [Skill](./skills.md) for one-click reuse next time.

**Depends on**: Creating an Agent · Connecting a Server to Run Tasks · Chat · Tools · Publishing an App

## Recipe 2: Build a domain-expert Agent and keep refining it

**Typical goal**: "I want an expert assistant that understands our industry/business" (legal contract review, bioinformatics data analysis, financial risk control…).

**Orchestration path**:

1. **Start with Guided create**: use the **Guided create** mode of [Creating an Agent](./create-agent.md). The AI asks you a few rounds about the ambiguous points, helping you describe the specialized need more precisely than writing it all at once.
2. **Add the specialized abilities**: domain tasks often need special tools or knowledge — add tools via [Extending an Agent with Tools](./extend-agent-with-tools.md), or feed it domain material per [Building a Knowledge Q&A Agent](./build-knowledge-qa.md).
3. **Try and iterate**: test with real cases in [Chat](./chat.md) and adjust when unsatisfied. A built app can also be improved with one sentence (see version updates in [App Center](./app-center.md)).
4. **Share with the team**: use [Resource Groups & Sharing](./resource-groups-sharing.md) to share it with colleagues, or publish it as an app.

**Depends on**: Creating an Agent · Extending an Agent with Tools · Building a Knowledge Q&A Agent · Chat · Resource Groups & Sharing

## Recipe 3: Make something happen automatically on a schedule

**Typical goals**: "Auto-summarize yesterday's data and send it to me every morning," "Watch a metric and alert when it's abnormal."

**Orchestration path**:

1. **First build an Agent that does the task once** (Recipe 2). Make sure triggering it manually does the job well.
2. **Hand it to Event Tasks**: use [Event Tasks](./events.md) to set it as a recurring or autonomous task, and the platform runs it on schedule automatically.
3. **Watch the results**: check each run in the Event Task's run records.

**Depends on**: Creating an Agent · Event Tasks · Chat

## Recipe 4: Turn internal material into company-wide self-service Q&A

**Typical goal**: "Colleagues keep asking about policies/processes/product details, and I want them to self-serve."

**Orchestration path**:

1. Feed the material to an Agent per [Building a Knowledge Q&A Agent](./build-knowledge-qa.md).
2. Publish it as a public app with [Publish Your First App](./publish-first-app.md); share the link in a chat group, and colleagues can ask without signing in.
3. Iterate on feedback in one sentence (version updates in [App Center](./app-center.md)).

**Depends on**: Building a Knowledge Q&A Agent · Publishing an App · App Center

## Not sure which recipe fits?

Just ask the **Manual Assistant** (nav "🤖 手册助手" on the home page) and describe your goal as-is — "I want AI to help me do XX." It judges whether that's a single operation or a goal that needs a combination, and gives you the matching orchestration path with a manual citation for each step.
