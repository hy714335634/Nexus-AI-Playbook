---
title: Creating an Agent
sync:
  source_commit: ab4bae1c37761738f62e15ab8eedfc9a0a4cf352
  source_files:
    - api/v2/routers/agents.py
    - web/src/app/(authed)/create/**
  generated_at: 2026-05-08T14:55:41+00:00
  generated_by: docs-sync v2
---

# Creating an Agent

Nexus-AI offers two creation modes — **Quick Create** and **Guided Create** — suited to different scenarios. Click the left-hand navigation to open the creation page.

![Create Agent](/images/create-agent.png)

## Comparing the Two Modes

| | Quick Create | Guided Create |
|---|---------|---------|
| **When to use** | Requirements are clear; you know what the Agent should do | Requirements are vague; you only have an initial idea |
| **Flow** | Enter description → build directly | Enter description → AI asks follow-up questions → refine → build |
| **Time** | Fastest (jumps straight into building) | Slightly longer (you answer AI questions), but requirements are more precise |
| **Requirement quality** | Depends on how well you describe it | AI fills in what's missing — usually more complete |
| **Best for** | Experienced users with clear requirements | First-time users, complex needs, or uncertain details |
| **Multimodal support** | ✅ File attachments supported | ✅ File attachments supported |

::: tip Not sure which one to pick?
If this is your first time, or you haven't fully thought through your requirements, use **Guided Create**. The AI's questions will help you surface details you might otherwise miss.
:::

## Quick Create

Select the **Quick Create** tab to open this view:

![Quick Create](/images/quick-create.png)

### Step-by-Step

#### Step 1: Pick a Template (Optional)

The top of the page offers **4 built-in templates** covering the most common Agent types. Clicking a template card auto-fills the Agent name and requirement description.

| Template | Built-in Capabilities | When to Use |
|----------|----------------------|-------------|
| **Data Analysis Agent** | Read CSV/Excel, statistical analysis, chart generation, data summaries | Periodic reports, data exploration, business analysis |
| **Content Creation Agent** | Article writing, copy optimization, editing, multilingual translation | Marketing content, technical writing, copywriting |
| **Market Research Agent** | Web search, information synthesis, competitive analysis, report generation | Industry research, competitor monitoring, market trends |
| **Technical Development Agent** | Code writing, code review, architecture design, documentation | Dev assistance, refactoring, technical design review |

::: info
A template is just a starting point. Modify and extend its description with your specific business context and requirements.
:::

#### Step 2: Name Your Agent (Optional)

Enter a name in the **"Agent Name"** input. If you leave it blank, the system will auto-generate one from your requirement description.

Naming tips:
- Use concise, meaningful names (e.g., "Medical Literature Assistant", "AWS Pricing Advisor")
- Avoid generic names (e.g., "Agent1", "Test")

#### Step 3: Describe Your Requirements

In the **"Detailed Business Requirements"** text box, describe the Agent you want in natural language. This is the single most important input in the entire flow.

**Elements of a good requirement description:**

| Element | Importance | Example |
|---------|-----------|---------|
| **Core functionality** | ⭐⭐⭐ Required | "Search papers on PubMed" |
| **Data / service sources** | ⭐⭐⭐ Required | "Connects to the PubMed API" |
| **Input format** | ⭐⭐ Recommended | "User enters keywords or uploads a PDF" |
| **Output format** | ⭐⭐ Recommended | "Generate citations in APA format" |
| **Language** | ⭐ Optional | "Respond in English" |
| **Behavioral constraints** | ⭐ Optional | "State uncertainty explicitly; never fabricate citations" |

**A complete example:**

> Create a medical literature research assistant with the following capabilities:
>
> 1. Search papers on a given topic in the PubMed database
> 2. Accept PDF uploads; parse the full text and extract abstract, conclusions, and key data
> 3. Generate APA-format citation lists automatically
> 4. Produce a topical review report from multiple papers
> 5. Support conversations in both Chinese and English
> 6. When information is uncertain, state it clearly — never fabricate citations

#### Step 4: Attach Files (Optional)

Click the **📎 attachment button** next to the input to upload files that supplement your requirements:

| Format | Purpose | Best Practice |
|--------|---------|---------------|
| **PDF** | Product specs, business process documents | Upload existing business documents so the AI understands your context |
| **Excel / CSV** | Data samples | Upload a sample dataset so the AI learns your columns, types, and format |
| **Images** (JPG/PNG) | Reference designs, UI screenshots | Upload mockups or screenshots of an existing system |
| **Word documents** | Detailed requirements | If your requirements are long, put them in a Word document |

::: tip Why attachments matter
Attachments significantly improve build quality. For example, uploading a CSV sample lets the Agent learn your data's column names, types, and format, and generate analysis tooling tailored to your actual data.
:::

#### Step 5: Start the Build

Once everything looks right, click **Start Building**. The system will:

1. Create a new build project
2. Redirect to the [Build Progress](/using/build-progress) page
3. Run 8 Builder Agents cooperatively along a pipeline
4. Show real-time progress at each stage

### Build Tips

The bottom of the Quick Create page has a **"Build Tips"** area to help you write a better requirement description:

- State the Agent's primary responsibility and working scenario
- List the specific business tasks it needs to handle
- Identify the data sources or systems it needs to connect to
- Describe the expected input/output format and interaction style

## Guided Create

Guided Create is a signature feature of Nexus-AI. Through a multi-turn conversation with the AI, it helps you turn a vague idea into a precise requirement. The process is driven by the **Requirements Agent**.

![Guided Create](/images/guided-create.png)

### Step-by-Step

#### Step 1: Enter an Initial Idea

Select the **Guided Create** tab and describe your initial idea in the text box. It doesn't need to be detailed — one or two sentences is enough:

> I want an Agent that helps a customer support team

Page hint: *"You don't need to be detailed — the AI will ask follow-up questions to fill in the gaps."*

You can attach files here too.

#### Step 2: AI Asks Clarifying Questions

The **Requirements Agent** analyzes your description and asks a series of targeted questions designed to surface missing details.

**Typical question categories:**

| Dimension | Example Question |
|-----------|------------------|
| **Target users** | "Who will use this Agent — internal employees or external customers?" |
| **Core functionality** | "What types of tasks does the Agent need to handle?" |
| **Data sources** | "Which systems or databases does the Agent need to access?" |
| **Input method** | "How will users provide information — text, files, or both?" |
| **Output requirements** | "In what format should the Agent return results?" |
| **Language and tone** | "What style should the Agent's replies have?" |
| **Exception handling** | "What should happen when the Agent cannot complete a task?" |

**Answering tips:**
- Answers can be short or detailed; the AI judges whether the information is sufficient
- If you haven't decided on something, say "Not sure yet" — the AI will suggest a best-practice default
- You can ask your own questions in your answers, turning it into a two-way dialogue

#### Step 3: Multi-Turn Refinement

The AI may run **2–5 rounds of questions**, each building on your previous answers. Once it judges the information complete enough, it moves to the next step.

```
Round 1: Basic requirements and scenarios
  ↓
Round 2: Functional details and data sources
  ↓
Round 3: Behavioral constraints and exception handling
  ↓
(AI considers the information sufficient)
  ↓
Generate enhanced requirement document
```

#### Step 4: Review the Enhanced Requirement

Once information gathering is complete, the AI produces an **enhanced requirement document**, turning your vague idea into a structured, actionable specification:

**The enhanced requirement document contains:**
- **Agent positioning** — name, goal, use cases
- **Feature list** — features ranked by priority
- **Input / output spec** — supported input formats and output requirements
- **Tool and integration needs** — tools to develop or integrate
- **Behavioral constraints** — boundaries and limits on the Agent's behavior
- **Language and style** — response language and tone requirements

#### Step 5: Edit and Confirm

You can **edit the enhanced requirement document directly** in the text editor:

- ✏️ **Add** — include missing features or requirements
- 🗑️ **Remove** — delete content you don't need
- 🔄 **Adjust** — tweak priorities, wording, or parameters
- ➕ **Extend** — add more business detail

When you're done, click **Confirm and Start Building** to enter the automated build flow.

## A Side-by-Side Comparison

### Same Requirement, Different Paths

Suppose you want to create a "Customer Data Analysis Agent":

**Quick Create path:**
```
You enter:
"Create a customer data analysis Agent that reads CRM-exported
Excel files, analyzes customer distribution, purchase behavior,
and churn risk, and produces an analysis report."

→ Build starts directly (~5–8 minutes to complete)
```

**Guided Create path:**
```
You enter: "I want an Agent that analyzes customer data"

AI asks:
- "What is the source and format of the customer data?"
- "Which dimensions should it analyze?"
- "What should the report contain?"
- "Do you need predictive capabilities (e.g., churn prediction)?"

After you answer, the AI produces an enhanced requirement:
- Read Excel files exported from the CRM
- Analysis dimensions: customer distribution, purchase behavior, churn risk, RFM model
- Output: data summary + charts + actionable recommendations
- Bonus: churn-warning score

→ After confirmation, build starts (~8–12 minutes to complete)
```

The Agent produced by Guided Create is usually more complete (because the AI surfaced features like "churn-warning score" that you might not have thought of), at the cost of slightly longer elapsed time.

## After the Build Starts

Regardless of which mode you used, clicking build triggers the following:

1. **Project creation** — the system creates a new build project
2. **Redirect** — you are taken to the [Build Progress](/using/build-progress) page
3. **Pipeline starts** — 8 specialized Builder Agents run in sequence:
   - Orchestrator analyzes requirements and plans the build
   - Requirements Agent formalizes the requirement spec
   - Architecture Agent designs the technical architecture
   - Design Agent defines behavioral logic
   - Prompt Agent writes the system prompt
   - Tools Agent builds the needed tools
   - Developer Agent writes the Agent code
   - DevManager Agent reviews code quality
   - Agent Deployer performs deployment
4. **Real-time monitoring** — watch the status of each stage on the Build Progress page
5. **Build complete** — once all stages finish, the Agent is immediately available for testing conversations

::: info During the build
You can leave the page and do other things while the build runs. If notifications are enabled, you'll be notified on completion or failure.
:::
