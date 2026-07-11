# Personal AI Toolbox

This is a beginner-friendly terminal project you can grow over time.

It helps you practice:

- navigating folders in PowerShell
- saving notes from the terminal
- searching text with `rg`
- preparing clean exports to paste into ChatGPT or Grok
- using git to track your changes

## Project layout

- `toolbox.ps1` - the command-line tool
- `data/notes/` - daily notes you capture
- `data/exports/` - weekly bundles for AI review
- `prompts/weekly-review.md` - a ready-made prompt for ChatGPT or Grok

## First terminal commands to learn

Open PowerShell in this folder and try these:

```powershell
Get-Location
Get-ChildItem
Set-Location .\personal-ai-toolbox
Get-ChildItem
```

What they do:

- `Get-Location` shows where you are
- `Get-ChildItem` lists files and folders
- `Set-Location` moves into a folder

## Toolbox commands

Run the tool like this:

```powershell
.\toolbox.ps1 help
```

## Guided learning shell

If you want a safer practice flow, start the logged learning shell:

```powershell
Set-Location C:\Users\localadmin\Documents\Playground\personal-ai-toolbox
.\start-learning-shell.ps1
```

What it does:

- moves you into the project folder
- starts a PowerShell transcript in `logs/`
- gives the shell a clear `LEARNING PS` prompt

This is not a true operating system sandbox, but it is a good training shell because every command and result is saved for review.

When you want to stop logging, run:

```powershell
Stop-Transcript
```

Capture a note:

```powershell
.\toolbox.ps1 capture "Learned how Get-ChildItem works #terminal #learning"
```

List recent notes:

```powershell
.\toolbox.ps1 list
```

Find text across your notes:

```powershell
.\toolbox.ps1 find terminal
```

Create a weekly export for AI:

```powershell
.\toolbox.ps1 export-week
```

Print a quick weekly summary:

```powershell
.\toolbox.ps1 review-week
```

## Suggested learning flow

1. Capture a few real notes for a few days.
2. Search them with `find`.
3. Run `export-week`.
4. Open the generated file in `data/exports/`.
5. Paste it into ChatGPT or Grok with the prompt from `prompts/weekly-review.md`.

## Beginner git commands

These are safe, useful starter commands:

```powershell
git status
git add .\personal-ai-toolbox
git commit -m "Start personal AI toolbox"
```

What they do:

- `git status` shows changed files
- `git add` stages files for the next commit
- `git commit` saves a checkpoint in git history

## Good prompts to try

Ask ChatGPT or Grok things like:

- "Explain what this PowerShell script is doing in plain English."
- "Help me add a new command called archive-month."
- "Review this weekly export and identify themes, priorities, and next actions."
- "Teach me the terminal commands used in this project one by one."

## Next upgrades

When you are ready, we can add:

- tags dashboard
- monthly review exports
- file cleanup helpers
- note templates
- optional Python version
