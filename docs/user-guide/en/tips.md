---
title: Tips & Best Practices
sync:
  source_commit: 9d40a32f2bad2c7858b3ed0cfb4390e1bd603a30
  source_files:
    - CLAUDE.md
    - README.md
  generated_at: 2026-07-12T14:12:40+00:00
  generated_by: docs-sync v2
---

# Tips & Best Practices

You already know how the features work — this page is about using them well: how to describe what you want clearly, how to chat efficiently with an Agent, and how to save up your best results and reuse them. These are small, easy habits that noticeably improve your results. Read whichever ones apply to you.

::: tip One thing to remember
**How good your results are comes down mostly to how clearly you describe what you want.** Most of this page is about exactly that.
:::

## 1. Describe what you want, better

When you create an Agent, the description you write directly decides how useful the result is. A good description usually covers three things: **who it's for, what it should do, and what the result should look like**.

| Too vague | Better |
|-----------|--------|
| Help me with documents | Create an assistant that reads PDF contracts, pulls out the key terms, and lists them |
| Analyze data | Create an assistant that analyzes the monthly sales sheet, spots what's up and down, and writes a short summary |
| Make a customer-service bot | Create an assistant that answers common customer questions based on our product guide |

![agents-new](/images/agents-new.png)

A few practical habits:

1. **Spell out the "input" and the "output"**: what it receives (a spreadsheet? some text?) and what you want back (a list? a summary? a chart?).
2. **Give an example**: a single "for instance, if it sees XX, do YY" line helps the result match your intent.
3. **Keep each Agent focused on one thing**: instead of one do-everything assistant, build a few specialized ones — each does its job better.
4. **Write the way you normally talk**: no technical or specialist jargon needed — that's the whole point of the platform.

::: tip Not sure how to phrase it?
Just adapt one of the lines in the table above. If you're not happy with the result, you can always have it adjust — you don't need to get it perfect on the first try. See [Creating an Agent](./create-agent.md) for detailed steps and [Build Progress](./build-progress.md) for what happens next.
:::

## 2. Don't expect perfection on the first try

Building an Agent isn't a one-shot deal. **Treat the first version as a draft**, try it on a couple of real tasks, then tell it what to change — that's far easier than agonizing over "how do I write the perfect description in one go."

- Once it's built, test it on **something you originally wanted it to do** and check the result.
- If it's off, just say so in the chat — "change this to…", "make the result shorter" — or go back to the create page and adjust.
- For big changes, just build a new one and keep the old for comparison; keep whichever works better.

## 3. Chat efficiently with an Agent

![chat](/images/chat.png)

- **The send shortcut is Shift + Enter**: pressing Enter only adds a new line, it doesn't send. This is the opposite of most chat apps, so it's an easy trip-up.
- **One task at a time**: instead of cramming five things into one message, say them one by one — the answers will be sharper.
- **Give enough background**: state the relevant context, limits, and preferences up front so it doesn't have to guess and you save a round trip.
- **Stop it if it's going the wrong way**: while it's replying, the send button turns into **Stop Generating** — click it to interrupt, and whatever's written so far is kept, so you can rephrase.
- **One topic per session**: you can open several sessions under one Agent, each independent — one for real work, one for experiments — and find them all later.

::: tip Long conversation getting slow?
Click **Compact Context** on the chat toolbar to have the system tidy up and condense earlier content so the Agent keeps replying smoothly. See [Chat](./chat.md) for the day-to-day details. Want to jump to a specific Agent quickly? Try the [Spotlight Command Palette](./spotlight.md) — press `⌘K`, type a few characters, and go straight there.
:::

## 4. Make good use of files

You can attach files to a chat so the Agent works from their contents — much easier than typing everything in.

- You can upload images, Excel, Word, PDF, and more — or **paste a screenshot** directly.
- Send the files along with your question.
- To find files the Agent produced, click **Files** at the top and look in **Workspace** to view and download them.

## 5. Save up your best results

As you go, you'll build up a collection of Agents, conversations, and files. A little organizing means you can find and reuse them fast next time, instead of starting over each time.

| Do this | Why it helps |
|---------|--------------|
| Group related work into a [Project](./projects.md) | Finding things no longer means digging through history |
| [Favorite](./chat.md) the Agents you use often | One click to open them next time |
| Publish a proven Agent as an [App](./app-center.md) | You and your teammates get it ready to use |
| Capture a way of working as a [Skill](./skills.md) | Reuse it in a new scenario without re-teaching |

::: tip It gets easier the more you use it
The platform is designed so the more you accumulate, the more useful it gets. A minute spent organizing today saves ten minutes of repeat work tomorrow.
:::

## 6. Make your Agent more capable and more automatic

Once the basics feel comfortable, you can go further in a few directions:

- **Connect it to real data and systems**: add [Tools](./tools.md) to an Agent, or connect it to your company's existing systems (see [Integration Center](./integration-center.md)), so it can look up real information and get real work done.
- **Let it run on a schedule**: use [Scheduled Tasks](./events.md) to have the Agent work automatically by time — for example, produce a report every morning without you prompting it.
- **Summon it anywhere**: the [Built-in Assistants](./assistants.md) in the interface can look things up, answer questions, and point you to the right place — ask them first when you're unsure.
- **Jump anywhere instantly**: use the [Spotlight Command Palette](./spotlight.md) (`⌘K`) to search and jump to any Agent, app, page, or past conversation without navigating menus.

## 7. Don't panic when something goes wrong

- **A build stalls or fails**: refresh the [Build Progress](./build-progress.md) page first to see if it has actually moved on; if it truly failed, start it again or describe your requirement more clearly.
- **The reply appears piece by piece**: that's the normal look of a real-time answer, not a freeze — just wait for it to finish.
- **Can't log in**: first check the URL, username, and password for typos (mind the capitalization); if it still won't work, contact your administrator.
- **Really stuck**: ask a [Built-in Assistant](./assistants.md) in the interface, or contact your administrator.

## FAQ

**I'm not technical — can I still use Agents well?**
Yes. This platform is made for business users who don't write code. Describing what you want and asking questions the way you normally talk is exactly the right way to use it.

**I keep struggling to write a good description. Any shortcut?**
Yes. Cover the three points — who it's for, what it does, what result you want — adapt one line from the table in the first section, and hand it over to test. Test, then adjust: it's faster than trying to think it through in your head.

**Will my Agents and past conversations get lost?**
No. They all stay in your account, still there next time you log in, ready to reuse.

**If I open several sessions under one Agent, will they mix together?**
No. Each session is independent, so you can safely use one for real work and one for experiments.

**What should I learn next?**
Go back to the [Learning Path](./learning-path.md) and pick the next page that matches your goal. You might also check out the [Spotlight Command Palette](./spotlight.md) to learn site-wide quick navigation, or [Manage Agents](./manage-agents.md) to see how to organize and maintain your Agent list.
