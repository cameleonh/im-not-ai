# humanize-korean

## Purpose

`humanize-korean` revises Korean prose that sounds AI-like, translation-like, overly mechanical, or stylistically mismatched. It is designed for Korean writing first, with special support for academic prose and the user's own editorial style.

The skill is a writing-quality workflow, not an AI-detector bypass tool.

## When To Use

Use this skill for:

- Korean manuscript, report, essay, proposal, email, or public-facing prose revision.
- Korean academic style polish for papers, theses, and journal-style sections.
- Translationese cleanup where the meaning is right but the Korean rhythm is awkward.
- User-style revision such as Honey_hoony style, when the user provides or references their own writing.
- Follow-up requests such as making the revision weaker, stronger, more academic, or limited to one paragraph.

Use `writing-anti-ai` instead when the input is mainly English or Chinese general prose and the task is generic AI-pattern cleanup.

## Workflow

1. Identify task type, language, genre, revision strength, and minimum severity.
2. Detect AI-like, translation-like, or register-mismatched patterns using `references/ai-tell-taxonomy.md`.
3. Rewrite using `references/rewriting-playbook.md`.
4. For academic prose, load `references/academic-style-sources.md`.
5. For user-style prose, load `references/user-style-profile.md`.
6. Audit meaning, facts, numbers, names, citations, scope, and certainty.
7. Review naturalness and return the revised text with compact notes.

## Included Files

- `SKILL.md`: main routing and execution instructions.
- `agents/openai.yaml`: role prompts for environments that can use agent-style review.
- `references/ai-tell-taxonomy.md`: Korean AI-like and translation-like pattern taxonomy.
- `references/rewriting-playbook.md`: rewrite rules and examples.
- `references/academic-style-sources.md`: academic style guidance based on public source conventions.
- `references/user-style-profile.md`: user writing-style profile.
- `references/web-service-spec.md`: optional web/API/product extension notes.

## Boundaries

- Preserve meaning, facts, claims, numbers, dates, names, citations, legal text, equations, and quoted text.
- Do not add new evidence, examples, claims, or citations.
- Do not imitate a living author's distinctive personal style.
- Do not claim that text will pass an AI detector.
- Do not remove required AI-use disclosure.

## Meta-Skill Routing

`paper-writing-mode` should route Korean paper prose, Korean academic tone polish, translationese cleanup, and Honey_hoony/user-style revision to this skill.
