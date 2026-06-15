---
name: humanize-korean
description: Korean writing revision skill for naturalizing AI-like or translation-like Korean prose while preserving meaning, facts, numbers, names, citations, and genre. Use for requests such as "AI 같은 글 자연스럽게", "번역투 줄여줘", "한국어 문체 다듬어줘", "내용은 유지하고 톤만 정리", "논문 문체로 다듬어줘", "내 스타일로 써줘", "Honey_hoony 스타일", "academic Korean/English style polish", and follow-up edits such as changing revision strength, rerunning a paragraph, or reviewing residual awkwardness. This is a writing-quality workflow, not a detector-evasion or authorship-misrepresentation tool.
---

# Humanize Korean

한국어 문체 자연화와 학술 문체 정리를 수행한다. 목적은 "AI가 쓴 사실을 숨기기"가 아니라 번역투, 기계적 병렬, 과한 접속, 리듬 단조로움, 부정확한 학술 문체를 줄여 독자가 자연스럽게 읽는 글로 고치는 것이다.

## Core Rules

1. Preserve meaning first: facts, claims, numbers, dates, units, names, citations, legal text, equations, and quoted text must remain equivalent to the source.
2. Revise only for style, rhythm, register, structure clarity, and Korean/English academic convention. Do not add new evidence, examples, claims, or citations.
3. Keep the user's genre and audience: report, paper, blog, speech, proposal, email, and promotional copy require different levels of formality.
4. Avoid authorship deception. Do not promise that text will pass an AI detector or claim that a text was not AI-assisted.
5. For living authors or professors used as references, extract general academic-writing conventions only. Do not imitate a distinctive personal style or copy phrases.

## Runtime Selection

Use the best available execution surface.

- In Claude Code with subagents available: use `agents/*.md` as role prompts for detector, rewriter, fidelity auditor, and naturalness reviewer. Team/parallel review is allowed.
- In Codex or any environment without Claude subagents: run the same roles sequentially in the main agent. Do not require `Agent`, `TeamCreate`, `TaskCreate`, or a named model.
- In Claude.ai custom skill mode: use the flattened 4-step flow packaged under `dist/claude-ai/humanize-korean`.

The workflow must still produce the same logical artifacts even if they are not written to disk: detection findings, rewrite draft, fidelity audit, naturalness review, final output.

## Reference Loading

Load only the references needed for the task.

- Always load `references/ai-tell-taxonomy.md` for Korean AI-like/translation-like pattern categories.
- Always load `references/rewriting-playbook.md` before rewriting.
- Load `references/academic-style-sources.md` when the user asks for 논문, 학술, academic, paper, journal, thesis, Harvard/SNU style, or professor/PDF-based writing guidance.
- Load `references/user-style-profile.md` when the user asks for 내 스타일, Honey_hoony style, or asks to use their own essay/writing as a reference.
- Load `references/web-service-spec.md` only for web/API/product requests.

Do not download or store copyrighted PDFs unless the user explicitly asks and the source license allows redistribution. Prefer source URLs and high-level style notes.

## Workflow

### 1. Intake

Identify:

- `task_type`: detect only | revise | academic polish | follow-up rerun | web extension.
- `language`: Korean | English | mixed.
- `genre`: paper | report | blog | speech | proposal | email | other.
- `revision_strength`: conservative | standard | assertive. Default to standard.
- `min_severity`: S1 | S2 | S3. Default to S2.

If the input is under 100 characters, warn that style detection is unreliable but continue if the user clearly wants revision.

### 2. Detect

Scan the text using `ai-tell-taxonomy.md`.

For each finding record:

- category id and label
- severity
- scope: span | sentence | paragraph | document
- exact text span when applicable
- reason
- suggested revision

Treat academic and technical prose carefully. Formal nouns, passive voice, English terms, and signposting are not automatically wrong in papers. Mark them only when they are repetitive, vague, translated, or genre-inappropriate.

### 3. Rewrite

Revise from the findings using `rewriting-playbook.md`.

Apply these constraints:

- Prefer local edits over rewriting whole paragraphs.
- Preserve source order unless a sentence is genuinely incoherent.
- Keep technical terms if they are field-standard.
- Keep direct quotations untouched.
- Monitor rough change rate: 5-25% is normal, 30% needs a warning, 50% requires stopping and reporting risk.

For academic polish, use `academic-style-sources.md`:

- Korean papers: problem/method/result/implication order, restrained claims, clear operational definitions, and cautious causal language.
- English papers: thesis-first paragraphs, explicit scope conditions, precise verbs, signposted limitations, and evidence-led transitions.

For user-style editorial writing, use `user-style-profile.md`:

- Start from a public principle, move through a concrete failure, diagnose the institutional mechanism, and end with a firm reform demand.
- Keep the user's direct, controlled critical tone without copying phrases verbatim.

### 4. Fidelity Audit

Compare source and draft.

Rollback or revise any edit that changes:

- numbers, dates, units, names, citations, legal text, equations, direct quotations
- claim direction, causality, certainty level, actor, sequence, quantity, or scope
- technical meaning or evaluation criteria

When unsure, preserve the original meaning and explain the uncertainty.

### 5. Naturalness Review

Review the revised text for:

- remaining translation-like or AI-like patterns
- over-polishing, literary drift, excessive colloquialization, or genre drift
- repetitive sentence endings or mechanical transitions
- academic register mismatch

If major issues remain, run at most two additional targeted passes. Do not keep looping indefinitely.

### 6. Output

Return:

1. Revised text.
2. Short summary of what changed.
3. Fidelity notes if any risky edit was avoided or rolled back.
4. For academic polish, mention which style convention was applied, not which author was imitated.

If the user asks for detailed artifacts, include a compact table of findings and before/after examples.

## Follow-up Handling

- "강도 낮춰": keep only S1 and high-confidence S2 edits.
- "강도 높여": include S3 and paragraph-level rhythm edits, still preserving meaning.
- "이 문단만": rerun detection and rewrite only on that span.
- "논문 문체로": load academic style sources and adjust to academic register without adding citations.
- "탐지만": stop after detection and report findings.

## Safety Boundary

This skill may improve clarity and naturalness. It must not help fabricate authorship, hide policy violations, remove required AI-use disclosure, or guarantee detector evasion.
