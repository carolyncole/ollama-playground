---
name: rails-to-hanami
description: Guides converting this repo's rails_bookshelf Rails app into an equivalent Hanami app, one phase at a time, following the carolyncole/rails_to_hanami workshop. Use this whenever the user wants to port, migrate, or convert a controller, view, spec, model, or route from Rails to Hanami in this repo, asks to "start the Hanami conversion", mentions the Hanami rewrite/workshop, or asks about Hanami actions, repos, relations, structs, or routes for the books resource. Always consult this before hand-rolling Hanami setup commands or code from scratch — it has the exact container name, working directories, and code snippets that actually apply to this repo (which differ from the upstream workshop doc).
---

# Rails to Hanami Conversion

This repo's `rails_bookshelf/` Rails app has a matching Hanami conversion path, adapted from the
[carolyncole/rails_to_hanami workshop](https://github.com/carolyncole/rails_to_hanami/blob/main/commands-to-copy.md).
Follow it phase by phase — don't jump ahead or dump every phase's commands into the terminal at
once. The workshop's whole design is "get one spec passing, then move to the next," and later
phases assume earlier ones already work.

## Container & path conventions (this repo, not the upstream workshop)

The upstream workshop names its container `rails2hanami` and keeps the Rails app at the container
root. This repo is laid out differently — see `AGENTS.md`:

- Container name: `ollamaplayground` (not `rails2hanami`)
- Rails app: `/usr/src/app/rails_bookshelf`
- New Hanami app (you create this in phase 1): `/usr/src/app/bookshelf`, a sibling of `rails_bookshelf`
- Attach a shell: `docker exec -w /usr/src/app -it ollamaplayground bash`
- If the container exists but is stopped: `docker start ollamaplayground`
- Building/running the container for the first time follows `AGENTS.md`'s own Docker workflow
  section, not the workshop's — the ports (3001/2301) already match, only the image/container name
  differs (`ollamaplayground`).

Every command in the reference files below already has these substitutions applied, in the form
`docker exec -w <working-dir> -it ollamaplayground <command>`, so the working directory is always
explicit. You don't need to re-translate anything from the upstream workshop yourself.

## How to run this skill

1. Confirm the `ollamaplayground` container is running (`docker ps`, or ask the user). If it needs
   to be built/started, that's one-time setup per `AGENTS.md`, not part of this conversion.
2. Work through the phases below **in order**. Read only the reference file for the phase you're
   currently on — don't preload the others; each is scoped to stay under the context you need for
   that step.
3. After each phase, run that phase's spec(s) before moving on. If something fails, fix it within
   the current phase rather than pushing forward — the next phase's steps assume a green spec.
4. Phases 9 and 10 are exercises: hints only, no full solution. Implement them using the
   repo/action patterns established in phases 1–8, and reach for the hints only if stuck.

## Phases

| # | Phase | Reference file |
|---|-------|-----------------|
| 1 | Generate the Hanami app, share the SQLite DB with Rails, create the `books` relation/repo | `references/01-initial-setup.md` |
| 2 | Define Hanami routes, generate actions/views/templates for the `books` resource | `references/02-routes-actions.md` |
| 3 | Copy over Rails system specs and views, fix up spec syntax for Hanami | `references/03-views-specs.md` |
| 4 | Wire up flash notices and session cookies | `references/04-flash-notices.md` |
| 5 | Make the Book **show** page work | `references/05-book-show.md` |
| 6 | Make the Books **index** page work | `references/06-books-index.md` |
| 7 | Port the Rails application layout (CSS, favicon, CSRF) | `references/07-application-layout.md` |
| 8 | Make the Book **new/create** flow work | `references/08-book-new.md` |
| 9 | Exercise: implement Book **delete** | `references/09-exercise-delete.md` |
| 10 | Exercise: implement Book **edit/update** | `references/10-exercise-edit.md` |

Load the reference file for the current phase, execute its steps, verify its spec(s) pass, then
move to the next row.
