---
name: unslop
description: "Remove AI writing tells from prose you are about to commit or publish: markdown docs, code comments, commit messages, PR bodies, and issue text. Run it only when the user asks for it by name, with /unslop, 'unslop this', 'unslop the diff', or 'clean up this writing'."
disable-model-invocation: true
---

# Unslop

Rewrite prose to remove the patterns that mark text as machine-written. Keep the meaning. Keep the author's voice.

Claude Code honors the `disable-model-invocation` field above, so this skill never fires on its own. Codex ignores that field. **In Codex, do not run this skill unless the user asks for it by name.**

## Pick the target

| The user typed | Act on |
| --- | --- |
| `/unslop` with no argument | Prose in the working-tree changes. See below. |
| `/unslop <path>` | That whole file. |
| `/unslop <PR number>` or a PR URL | The PR title and body, read with `gh pr view <n> --json title,body`. |
| `/unslop` and pasted text | That text only. Return the rewrite. Change no file. |

With no argument, find the changed prose this way:

1. Run `git status --porcelain` and `git diff HEAD` to list the changed and new files.
2. Take the prose from them: markdown files, code comments, doc strings, and README text.
3. Rewrite **only the lines the diff adds or changes.** Do not rewrite the rest of the file. An unrelated whole-file rewrite hides the real change in the diff.
4. If the branch has no uncommitted changes, say so and stop. Do not guess a target.

## Never rewrite

- Code, identifiers, file paths, commands, and configuration values.
- Text quoted from a tool, a log line, an error message, or another person.
- Strings a user of the product reads. Those follow the project's own copy rules, not this skill.
- Anything a person wrote by hand, unless the user names that file.

## Process

1. Read the target.
2. Check it against every rule below.
3. Rewrite. Keep the meaning, the facts, the numbers, and the file paths exactly.
4. Ask yourself once more, "What still marks this as machine-written?" Fix what you find.
5. Report the edits as a short list. Give the rule number for each one.

Editing a local file needs no approval. **Ask before you write to GitHub.** A PR body, an issue, or a comment is public, so show the rewrite first and wait.

## Rules

The numbers are stable identifiers. Other skills cite them. A deleted rule leaves a gap, so the list has gaps by design.

Rules 27 to 34 overlap the Simplified Technical English output style that Claude Code already runs. They stay in this list because Codex has no such style, and this skill is the only copy it reads.

### Content

3. **Decorative "-ing" clauses.** "highlighting the need for", "ensuring reliability", "reflecting a shift toward", "showcasing", "fostering". Delete the clause, or replace it with the fact it stands in for.
5. **Vague attribution.** "Experts believe", "Industry reports suggest", "Some argue". Name the source, link it, or delete the sentence.

### Language

7. **AI vocabulary.** additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (when abstract), pivotal, showcase, tapestry, testament, underscore, vibrant. Use the plain word.
8. **Long ways to say "is".** "serves as", "stands as", "boasts", "features", "represents". Write "is" or "has".
9. **"Not just X, but Y."** Also "It's not about X, it's about Y." State the point once, directly.
10. **Groups of three.** Three examples, three adjectives, three clauses, every time. Use the number the subject actually has.
11. **Synonym cycling.** The same thing called a worker, a service, a process, and a handler in one paragraph. Pick one name and repeat it.
12. **False ranges.** "from performance to security", where the two ends are not on a scale. List the items.

### Style

13. **The em dash as a crutch.** One em dash in a paragraph is fine. Three is a tell, and so is an em dash that replaces a period. If the clause after it is a whole thought, end the sentence.
14. **The colon as a connector.** A colon before a list or an example is correct. A colon in the middle of a sentence, joining two clauses that a period would join better, is not.
15. **Bold on every proper noun.** Bold marks the one thing a scanner must not miss. Bold on every product name marks nothing.
16. **Bullet lists with restating headers.** The tell is a bold label followed by a colon and a line that says the label again: "**Performance:** Performance improved by 12%." Write it as prose. A bold lead-in that ends in a period and is followed by new detail is fine.
17. **Title Case Headings.** Use sentence case.
18. **Emoji in headings and bullets.** Remove them. An emoji that carries meaning, such as a warning marker the project already uses, can stay.
19. **Curly quotes and curly apostrophes.** Replace with straight ones.

### Communication artifacts

20. **Chatbot phrases.** "I hope this helps", "Let me know if you need anything else", "Of course!", "Certainly!", "Great catch!", "Found it!". Delete.
22. **Flattery.** "Great question", "You're absolutely right", "Excellent point". Answer instead.

### Filler

23. **Filler phrases.** "in order to" becomes "to". "due to the fact that" becomes "because". "it is important to note that" is deleted whole. "at the end of the day" is deleted whole.
24. **Stacked hedges.** "could potentially possibly be argued that it might" becomes "may", or becomes a plain statement of what you know.
25. **Empty conclusions.** "The future looks bright." "This sets a strong foundation." Give the next step, the number, or nothing.

### Jargon

26. **Metaphor nouns that sound technical.** substrate, wedge, vector, locus, vantage, nexus, primitive (as a noun), harness (as a metaphor), surface (as in "API surface"), bedrock, scaffolding (as a metaphor), modality, paradigm, gold-plating, ratchet, evacuate (for moving code), endgame, north star, flywheel, blast radius, lever, plane, lane, posture. Each has a plain word. "Substrate" is "base". "Wedge in" is "add". "Vector" is "way". "Gold-plating" is "more than the job needs". "Ratchet" is "a limit that only tightens". "Evacuate" is "move out". "Blast radius" is "what this can break". Use the plain word.

### Plain speech

27. **Name the mechanism, not the feeling.** "types that follow your schema" and "SQL you can read" describe a feeling. "A column rename fails the build" and "`.toSQL()` returns the exact string sent to the database" describe a mechanism. Test each sentence: could it appear unchanged in another project's documentation? If yes, it says nothing about this one. Cut it.
28. **One idea per sentence.** If the reader has to read a sentence twice to parse it, split it or drop a clause. Keep sentences under 25 words.
29. **Active voice.** Find "is/are/was/were" plus a past participle, then name the actor. "Queries are validated" becomes "the compiler validates queries". Passive is correct only when the actor is unknown or does not matter.
30. **Adverbs propping up weak verbs.** "runs quickly" becomes "is fast", or becomes the measured time. "significantly improves" becomes the measured change. If the adverb carries the sentence, the verb is wrong.
31. **The plain word.** "utilize" becomes "use". "leverage" becomes "use". "facilitate" becomes "help". "numerous" becomes "many". "in the event that" becomes "if". "prior to" becomes "before".
32. **Mannered prose.** Aphorisms ("wire it or delete it"), sentence fragments for effect, code described as a person ("the plan holds it"), figurative verbs ("rides along", "stands on", "bites"). Say the literal thing.
33. **Over-compression.** Dropped articles, missing verbs, arrows, and abbreviations that make the reader decode instead of read. "Parser rejects bad date → exit 2, no write" becomes "The parser rejects a bad date, exits with code 2, and writes nothing."
34. **Vague amounts.** "a handful", "several", "most", "significant", "a number of". Give the number. If you do not know it, say that you do not know it.
35. **Claims about work you did not do.** "This fixes the bug" when no test ran. "Fully tested." "Production ready." Say what you ran and what it printed, or say that you did not run it.

## Report

End with a short list. One line per edit, in this shape:

```
docs/deployment.md:41  rule 26  "blast radius" -> "what this can break"
README.md:7            rule 17  title case heading -> sentence case
```

If the target was already clean, say so in one line. Do not invent an edit to fill the report.
