# AI video editor

A project folder for editing talking-head videos with Claude Code, based on the
"Your AI video editor" guide from AI with Kyle.

```
video-editor/
  footage/        your original recordings (never changed by Claude)
  references/     short clips whose style you like
  brand/          logo, colours, fonts
  exports/        previews and finished videos, one folder per job
  brief.md        this video's audience, outcome and length
  style-guide.md  your repeatable style (Claude fills this in)
  .claude/skills/video-editing/
    SKILL.md      the editing workflow Claude follows
    lessons.md    corrections saved for every future job
```

Video files in `footage/`, `references/` and `exports/` are not committed to git.

## Use it

1. Copy this folder to your computer (or clone the repo) and open Claude Code **inside `video-editor/`**, so the skill loads.
2. First time: ask *"Use the video-editing skill to set up the tools and make a five-second test video."*
3. Put a short recording in `footage/`, fill in `brief.md`, then ask *"Make the first cut."*
4. Add reference clips and brand files, then ask *"Learn my style from the references"*, then *"Make a 30-second style sample."*
5. Give corrections with the file and timestamp: *"In exports/…/first-cut-v1.mp4 at 0:16, keep the full word. Everything else is fine."*
6. When a correction should apply every time, say *"Save that as a lesson."* It goes into `lessons.md`.
7. Next recording: start a fresh chat and type `/video-editing` — Claude loads the skill, lessons and style guide, then asks for the new brief.

Tools needed: FFmpeg, Whisper, Node.js (for HyperFrames or Remotion). DaVinci Resolve is optional.
