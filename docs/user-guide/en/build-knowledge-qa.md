---
title: Build a Knowledge Q&A Agent
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - agents/generated_agents/**
    - prompts/generated_agents_prompts/**
  generated_at: 2026-07-12T14:24:01+00:00
  generated_by: docs-sync v2
---

# Build a Knowledge Q&A Agent

Got a pile of material—product manuals, policies, FAQs, training docs—and coworkers keep asking you what's in it? This guide shows you how to build a **Knowledge Q&A Agent**: hand it your material and it answers questions straight from it, so you don't have to dig through it or explain the same thing over and over. You describe everything in plain language—no coding.

::: tip Who this is for
Business users in marketing, operations, support, HR, admin, and similar roles. All you need is a browser and the ability to gather your material into files.
:::

::: tip Before you start
It helps to have read [Creating an Agent](./create-agent.md) and [Chat & Sessions](./chat.md) first, so you know how to build an Agent and chat with it. This guide ties those together into an assistant that answers "from the material".
:::

## What is a Knowledge Q&A Agent

A general-purpose assistant answers from the broad knowledge it already "learned", so it has no idea about things specific to your company (like "how many days is our return window"). It simply doesn't know.

A **Knowledge Q&A Agent** is different: you feed it the relevant material first, and it answers **based on the material you gave it**. That way it can accurately answer the questions only your team knows the answers to—instead of making something up.

A few common uses:

| Problem you want to solve | Material you hand it |
| --- | --- |
| Support keeps getting the same questions | Product specs, FAQ list |
| New hires keep asking how a process works | Employee handbook, procedures |
| Too many policy clauses to remember | Policy documents, contract templates |
| A long report you want to ask about | The report, data notes |

### Real scenario: Company-wide self-service policy Q&A

Say you work in HR and your company has 200 pages of internal policy documents that get revised every quarter. Before, whenever a colleague had a question about leave policy, expense claims, or transfer rules, they pinged you directly — dozens of messages a day.

Now you can:

1. Upload the policy documents and build a Knowledge Q&A Agent.
2. [Publish it as an app](./publish-first-app.md) and drop the link in the company-wide chat.
3. 500 colleagues can self-serve policy questions 24/7, no waiting for your reply.
4. Next quarter the policies update? Hand it the new files via "Update" and it immediately knows the latest answers.

This is exactly where a Knowledge Q&A Agent shines: **material that changes periodically + many people need to look up the same content repeatedly**. You maintain one Agent and save the entire team hours of repetitive back-and-forth.

## The flow at a glance

| Step | What you do | Rough time |
| --- | --- | --- |
| 1. Prepare material | Gather what it should "understand" into files | Depends on your material |
| 2. Create the Agent | Describe your request and hand over the material | A few minutes |
| 3. Let it build | The system builds the Agent automatically | 10–40 minutes |
| 4. Ask a few questions | Test in chat whether it answers accurately | A few minutes |
| 5. Refine | If answers are off, add material or adjust the request | As needed |

## Step 1: Prepare your material

First gather what you want the Agent to "understand" into files. The cleaner the material, the more accurate the answers.

- **Common formats supported**: documents, spreadsheets, images, and other everyday files.
- **Up to 10 files at a time**: if you have a lot, pick the most important ones, or merge scattered pieces into a few files.
- **Keep it clear**: material with clear headings and distinct entries works better than one dense wall of text.
- **Include only what belongs**: if anything is confidential or personal, confirm it's OK to include before uploading.

::: tip You can start without files
If your files aren't ready yet, you can write the key information directly into your request (see the next step). Add the files later by updating the Agent once your material is ready.
:::

## Step 2: Create the Agent and hand over the material

Now build the Agent. Two things matter: **say clearly in your request that it should answer from the material**, and **attach the material along with it**.

1. Open the create page (the **Create Agent** button at the bottom of the sidebar, or the create card at the top of the home page—whichever is closest).
2. Describe the assistant you want in the request box. Make these clear: who it serves, what kinds of questions it answers, and what to do when it can't answer. For example:

   > Create a support knowledge assistant: answer customer questions based on the product manual and FAQ document I upload. Keep answers short and conversational; if the material doesn't cover something, clearly tell the user "I couldn't find this in the material" instead of guessing.

3. Click **Add attachment** (the paperclip icon) next to the request box and select the material you prepared in [Step 1](#step-1-prepare-your-material).
4. Each file shows "Parsing… → Parsed" after upload. **Wait until they all show "Parsed"** before continuing.
5. Click **Build**. The page jumps to the build progress page.

![quick-create](/images/quick-create.png)

::: warning Wait for "Parsed"
If you click Build while a file is still "Parsing", the system asks you to wait. Only submit once every file shows "Parsed"—that's when the Agent can actually read the contents. If a file shows "Failed", remove it and try a different file or try again.
:::

::: tip Why write "say so if it's not there"
That one sentence matters. With it, when the Agent hits a question the material doesn't cover, it honestly says "couldn't find it" instead of inventing an answer that sounds convincing but is wrong. For Q&A, "I don't know" is safer than a wrong answer.
:::

## Step 3: Wait for the build

After you submit, you land on the **build progress page**, where you can see what the system is doing in real time. The icon before each stage shows progress: ✅ done, 🔄 in progress, ⏳ waiting in line.

![project-detail-stages](/images/project-detail-stages.png)

::: tip How long does it take?
Usually 10 to 40 minutes. Feel free to do something else in the meantime—the build runs in the background, and you can return to this page anytime for the latest progress. Once it's done, the Agent appears in your Agents list.
:::

For more on the build progress page, see [Creating an Agent](./create-agent.md#watch-your-agent-get-built).

## Step 4: Ask it a few questions

Once the build is done, it's time to check how accurately it answers.

1. Click **Chat** in the left sidebar to open the chat page.
2. In the left column's **Select Agent** dropdown, find the Agent you just built and select it.
3. Click **Create new session** to start a fresh conversation.
4. In the box at the bottom, ask a question the material **actually covers**, and press **Shift + Enter** to send.
5. It answers in real time, piece by piece. Check the answer against your material.

![chat](/images/chat.png)

It's worth testing each of these cases so you know where you stand:

| Test question | What you want to see |
| --- | --- |
| Something clearly in the material | Accurate answer, matching the material |
| Something not in the material | Honestly says "couldn't find it", no guessing |
| The same thing worded differently | Still answers correctly, not thrown off by rephrasing |

::: tip Add material on the fly
If you want it to reference a new file just for this chat, click the **attachment button** next to the input box, upload the file, and send it with your question. See [Chat & Sessions](./chat.md#uploading-and-viewing-files). This is for one-off cases; if you'll need the material long-term, add it to the Agent properly as in [Step 5](#step-5-refine-when-answers-are-off).
:::

## Step 5: Refine when answers are off

If the answers aren't good enough, there's no need to start over. Use this table to find the cause:

| Symptom | Usually because | What to do |
| --- | --- | --- |
| Can't answer a question | The material doesn't cover it | Add material that covers it |
| Answer doesn't match the material | Material is messy or outdated | Clean it up, remove old versions, then update |
| Wrong even though it's written down | That part is vaguely worded | Rewrite it clearly, with distinct headings and entries |
| Answers too wordy / too stiff | The tone wasn't specified | Add a line to your update, e.g. "keep it to three sentences, more conversational" |

The way to adjust is to **update the Agent**: on its detail page, describe your change in a sentence (like "add this latest price list" or "include the relevant clause number in answers"), and the system updates it automatically. For the exact steps, see [Managing Agents](./manage-agents.md).

::: tip When the material changes
When your material changes (a policy revision, an updated price list), add the new file via "Update" and tell it to go by the new material. The Agent won't automatically know you changed a file offline—you have to hand it the new version.
:::

## Let more people use it (optional)

Once it works well for you, you can turn this Knowledge Q&A Agent into a web app and publish it, so coworkers—or even customers—can ask by opening a link, with no login and no technical know-how. See [Publish Your First App](./publish-first-app.md). Once published, manage its versions and access in the [App Center](./app-center.md).

::: tip Have many sources and want automatic sync?
If your material lives in Confluence, Notion, Google Drive, or similar platforms, you can connect the data source in the [Integration Center](./integration-center.md) so the Agent stays current without manual uploads.
:::

## FAQ

**Will it leak the material I upload to others?**
Your Agent and its material are your personal resources—only you (and admins) can see them. Others can only use it once you deliberately [publish it as an app](./publish-first-app.md) or [share it](./resource-groups-sharing.md).

**What if I have too much material to upload at once?**
Up to 10 files at a time. If you have a lot, start with the most frequently asked topics for the first version and add the rest in batches later via "Update". You can also merge scattered pieces into a few more complete files.

**It still gets things wrong sometimes—is that normal?**
A Knowledge Q&A Agent answers from the material first, but it's not 100% error-free. So two things matter: tell it in the request to "say so if the material doesn't cover it", and double-check important conclusions against the source material yourself.

**Do I have to manually tell it which "look it up" tool to use?**
No. Just say in your request "answer based on the material I upload", and the platform automatically equips it with what it needs during the build. To learn where an Agent's abilities come from, see [Extend Agent with Tools](./extend-agent-with-tools.md).

**Reword the question and it can't answer?**
First confirm the material actually covers it. If it does but the Agent still can't answer, that part is probably too vaguely worded—rewrite it more clearly and update the Agent (see [Step 5](#step-5-refine-when-answers-are-off)).

## Related guides

- [Creating an Agent](./create-agent.md) — full walkthrough of Agent creation options
- [Publish Your First App](./publish-first-app.md) — turn your Q&A Agent into a link anyone can open
- [App Center](./app-center.md) — manage published app versions, access, and usage
- [Integration Center](./integration-center.md) — connect external data sources to auto-sync material
- [Orchestration Recipes — Recipe 4](./orchestration-recipes.md#recipe-4-turn-internal-material-into-company-wide-self-service-qa) — end-to-end orchestration path from upload to publish to iterate
