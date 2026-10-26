---
name: video-editing
description: Edit talking-head recordings in this project — set up tools, make a clean first cut from footage/, apply the approved style from style-guide.md, make portrait (9:16) versions, apply focused corrections, and save reusable lessons. Use when the user asks to edit, cut, style, caption, reframe or correct a video, or to start a new editing job.
---

# Video editing

You direct the edit. The tools do the work:

| Tool | Job |
|---|---|
| Whisper | Timed transcript with word timings |
| FFmpeg | Cuts, reframing, captions burn-in, export |
| HyperFrames or Remotion | Graphics and animation |
| DaVinci Resolve (optional) | Editable timeline for the user |

## Before every job

1. Read, in this order, and tell the user which files you actually loaded:
   - this skill
   - [lessons.md](lessons.md) — corrections saved from earlier jobs. Follow them.
   - `style-guide.md` (project root) — approved visual style
   - `brief.md` (project root) — this video's audience, outcome and length
2. If the brief is blank or a file is missing, ask for it before editing.
3. Give the job its own folder: `exports/<YYYY-MM-DD>-<short-name>/`. Put working files in `work/<same-name>/`.

## Rules that always apply

- **Never modify, move or delete anything in `footage/`, `references/` or `brand/`.** Write only to `exports/` and `work/`.
- **Never upload, publish or delete** anything. Explain any install or account access you need before doing it.
- **Never overwrite a preview.** Each new version gets a new name: `v1`, `v2`, … (e.g. `first-cut-v2.mp4`).
- **Always report the exact file path to open**, and anything you need the user to decide.
- Keep the speaker's meaning. A cut that removes the sentence introducing an example is wrong even if it sounds clean.
- Use only the real logo, fonts and colours in `brand/`. Never invent brand assets.
- Say when you could not inspect a file (picture or sound) instead of guessing.

## Stage 0 — Set up (first time only)

1. Check what's installed: `ffmpeg -version`, `whisper --help` (or `python -m whisper`), `node -v`, `npx hyperframes --version`.
2. Follow the official HyperFrames quickstart for the simplest supported setup:
   https://github.com/heygen-com/hyperframes/blob/main/docs/quickstart.mdx
   (Remotion alternative: https://www.remotion.dev/)
3. Make a **five-second test video** with a title and a simple animation into `exports/setup-test/`. Confirm it plays (`ffprobe` it, check duration and streams). If something fails, diagnose and give the smallest next step.

## Stage 1 — Clean first cut

Input: a recording in `footage/` and a filled-in `brief.md`.

1. Make a timed transcript with word timings, e.g.
   `whisper footage/<file> --model small --word_timestamps True --output_format json --output_dir work/<job>/`
2. Inspect the footage (sample frames with ffmpeg if needed) alongside the transcript.
3. Decide each section using this test:
   - **Does the take finish the thought?** Yes → candidate. No → find the complete replacement take.
   - **Does the cut keep the meaning?** Yes → check the words at the join. No → restore the missing context.
4. Remove: abandoned starts, accidental repeats, instructions spoken to the editor, production chat.
   Keep: useful examples, natural delivery, the full sign-off.
5. Save a **source-timed cut list** at `exports/<job>/cut-list.md`: each kept and cut section with source in/out times and a one-line reason.
6. Build a clean **landscape** first cut with the original speech. **No decorative graphics yet.**
7. Export a small playable preview (e.g. 720p H.264/AAC) and check every join: clipped first/last sounds, repeated fragments, missing context, audio sync. Compare source and preview around each cut.
8. Stop. Tell the user the file to review and wait for approval before styling.

## Stage 2 — Style

### Learn the style (when `style-guide.md` is empty or the user adds references)

1. Inspect each clip in `references/`, picture and sound. For each, describe pacing, framing, captions, graphics, and when supporting material appears.
2. Combine with what the user says they like and don't want.
3. Write a concise `style-guide.md`. Link each major choice to a reference filename + timestamp. Keep **observed details** separate from **proposed choices**.
4. Show the style guide and wait for approval before applying it.

### Style sample (always before the whole video)

1. Choose one ~30-second passage with a complete spoken point and a good reason to show a graphic or source.
2. Keep the approved speech and cut timing. Add **one** readable visual, timed to the relevant words.
3. Export a preview. Report which style choices you used, where the passage starts in the source, and the file to open. Wait for feedback.
4. Once approved, keep the sample — it becomes a reference for the rest of the video and the next job.

### Choosing motion — match the effect to the sentence

| The speaker is… | Use |
|---|---|
| Explaining a process | Animated diagram |
| Comparing choices | Side-by-side cards |
| Showing a tool | Screen + cursor |
| Quoting a brief or prompt | Prompt ticket |
| Changing format | Phone frame |
| Adding emphasis | Type + sound |

Start from the HyperFrames catalogue (https://hyperframes.heygen.com/catalog) or Remotion Elements (https://www.remotion.dev/elements), or build a custom component in the brand colours. Render a short test clip before using a component everywhere.

### Portrait version (9:16)

1. Pick one self-contained 30–45 second idea with an understandable opening and a complete ending for someone who hasn't seen the full video.
2. Show the user the chosen source timings first.
3. Reframe to 9:16 keeping the speaker and any demonstration visible. Add accurate, readable captions placed clear of the thing being explained and of platform buttons/caption areas.
4. Check first and last words, caption spelling, readability and framing. Export separately from the landscape version.

## Stage 3 — Corrections and lessons

### A focused correction

The user names a preview file, a timestamp, what to change and what already works.

1. Locate the matching source footage and explain the specific change.
2. Export a **short** preview covering the change plus the joins either side. Keep all other approved speech, timing and visuals.
3. Keep the previous preview; give the revision a new version name. Don't update the full export until the user has checked it.

### Saving the lesson

After the user approves a correction, ask: **will they want this next time?**

- **Yes** → add a short, general rule to [lessons.md](lessons.md) (e.g. "Every recording: use the complete take"). Check existing rules for conflicts first and show the exact change.
- **No** → record it in this job's `brief.md` only (e.g. "This recording: use take four").

Keep episode-specific timestamps and content decisions out of lessons.md. Don't claim the model was retrained — improvement comes from reading these files on the next job.

## Before the full export — checklist

- **Takes + meaning:** opening uses the complete take; production chat and abandoned attempts removed; each example has its introduction.
- **Words at the joins:** listen around every cut for clipped beginnings/endings and repeated fragments.
- **Camera + sources:** hair and chin stay in frame; screenshots keep the words and controls being discussed readable; face inset doesn't cover them.
- **Motion + sound:** watch at normal speed for flashes, repetitive cut patterns, jerky movement; sound effects sit beneath speech.
- **Ending + next job:** full sign-off kept. Save the accepted export, cut list and useful corrections before the next recording.

## Tool links

- FFmpeg: https://www.ffmpeg.org/download.html
- Whisper: https://github.com/openai/whisper
- HyperFrames: https://hyperframes.heygen.com/quickstart
- Remotion: https://www.remotion.dev/
- DaVinci Resolve: https://www.blackmagicdesign.com/products/davinciresolve
