# Diagrams and Mermaid conventions

## Purpose

Store canonical architecture and flow diagrams as Mermaid source files and render to SVG for reviewers and docs.

## Locations

- Source files: `docs/diagrams/*.mmd`
- Rendered outputs: `docs/diagrams/*.svg`
- Map of diagrams and owners: `docs/diagrams/MAP.md`

## Conventions

- One diagram per `.mmd` file.
- Include a YAML header block at the top of each `.mmd` with:
  - **id**: unique diagram id
  - **owner**: GitHub handle
  - **description**: one-line summary
  - **last_updated**: ISO timestamp (CI can update)

Example header (top of file):

```text
%% id: service-map
%% owner: @platform-owner
%% description: High-level service and network map
%% last_updated: 2026-02-23T00:00:00Z
```

## Workflow

- Local: run `scripts/render-mermaid.sh` to produce SVGs.
- CI: `.github/workflows/render-mermaid.yml` renders on PRs and pushes.
- PRs that change `.mmd` must include updated `.svg` or rely on CI to produce preview artifacts.

## PR requirements

- Update `docs/diagrams/MAP.md` if nodes or owners change.
- Add a short textual summary in the PR describing the change.
- Ensure the render workflow passes.

## Troubleshooting

- If rendering fails, run `mmdc -i file.mmd -o file.svg` locally to see errors.
- Use the VS Code Mermaid preview extension for quick iteration.
