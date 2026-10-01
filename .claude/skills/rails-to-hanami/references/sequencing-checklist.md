# Suggested migration sequence, with rationale

This order is reconstructed from the actual PR history of a completed Rails→Hanami migration (pulibrary/orcid_princeton → orcid_princeton_hanami), not a theoretical plan. Use it as a checklist for a full-app port; skip to the relevant phase if you're only porting one slice.

## 1. Skeleton & tooling
CI config, linting (rubocop), formatting, session-secret setting, an empty Hanami app deploying through the same CI pipeline the Rails app already uses.
**Why first**: everything after this assumes CI is green and deploys work; debugging both a broken pipeline and a broken feature at once is miserable.

## 2. Static, no-DB, no-auth pages
A health-check endpoint, a version/build-info page, an external API status check. Zero dependency on the database or the auth stack.
**Why here**: this is the cheapest possible way to validate the full action → operation → view → template plumbing end to end, before the database or authentication add more variables. If something's wrong with the base `Action`/`View`/`Operation` classes, find out here, not while also debugging a login flow.

## 3. The core data model
Pick the one Rails model everything else hangs off of (usually "User" or equivalent). Ship its relation + repo + struct + migrations in one change, copying the original Rails migration filenames/timestamps verbatim so the two schemas stay comparable during the transition.
**Why before auth**: authentication needs somewhere to store/look up the user; build that storage layer and prove it with repo specs before wiring any HTTP-level login flow on top of it.

## 4. Shared UI chrome
Header, footer, layout, any design-system integration, favicon, homepage.
**Why here, not later**: almost every action spec written from this point on renders through the shared layout. If the layout is half-built, every subsequent feature's tests get noisy failures unrelated to the feature itself.

## 5. Associated models
Roles/join-tables, tokens, anything hanging off the core model — each as its own small change once the core model is solid, not bundled into step 3.
**Why separate from step 3**: keeps each change reviewable and testable in isolation; the core model's repo/struct specs shouldn't need to know about roles or tokens yet.

## 6. Authentication
Warden + OmniAuth wiring, session create/destroy actions, `current_user` as a `before` hook on the base Action.
**Expect a follow-up cleanup here.** A first cut of `current_user` that works isn't necessarily in the right layer — watch for logic creeping into the View/Context layer (it shouldn't be there; see layer-mapping.md §4) and fix it immediately once noticed, don't let it calcify. It's normal for a login-form action to be added and then deleted once pure SSO/OmniAuth redirect turns out to be sufficient — don't be precious about a provisional action you added.

## 7. Authorization
A struct boolean (`admin?`), a repo method to grant the role, a reusable `before :require_admin` guard hook — each as its own small change.
**Why after auth, not bundled with it**: authorization guard logic is much easier to get right and test once `current_user`/`require_authentication` already work reliably.

## 8. The primary user-facing feature, in every format Rails served it
If Rails served both HTML and JSON off one endpoint, land HTML first, then JSON — expect this to take more than one pass (the reference migration iterated over three PRs to get the HTML/JSON split right, not one).
**Why iterate rather than one big PR**: getting the format-negotiation `before` hook and the Tilt/jbuilder wiring right is fiddly; isolating it from the rest of the feature's logic makes it easier to debug.

## 9. Supporting actions
Anything secondary to the primary feature (token validation, revoke/refresh flows, etc.), each with its own operation if it has a failure mode.

## 10. Rake tasks and deployment
Port cron/report/admin rake tasks (put them straight in `lib/tasks/`, see layer-mapping.md §8 for why not `rakelib/`), then wire Capistrano deploy hooks for anything Hanami-specific (asset compile, admin-role sync).
**Why this late**: these depend on the repos/operations built in earlier steps; porting them earlier just means rewriting them once those layers stabilize.

## 11. The hardening wave — not optional
Once the feature set is functionally ported, expect (and schedule time for) a second wave of PRs that don't add features:
- **Idempotency fixes** on anything rake-driven (e.g. a "grant admin" task that shouldn't re-grant a role that's already present, a "reset defaults" task that needs to cleanly delete-then-recreate rather than assuming a fresh DB).
- **Consistency cleanup** on the Success/Failure pattern-matching style across operations, once there are enough of them to see the idiom clearly (see layer-mapping.md §12).
- **Local dev ergonomics** (devbox/lando/whatever this team uses for local Postgres) — often lands surprisingly late because it's not blocking, but it unblocks new contributors, so don't leave it forever.
- **Supporting a second auth backend** if the org is mid-transition (e.g. CAS → SSO/OIDC) — modeled as an operation subclass, not a rewrite (layer-mapping.md §12).

This wave is where real bugs get caught — non-idempotent rake tasks, auth edge cases, flaky test setups. Treat "the port works" and "the port is done" as two different milestones, and tell whoever's tracking the migration's progress that this phase is coming.

## The meta-lesson, stated plainly
Almost nothing in the reference migration was landed "perfectly" on the first PR for a given piece of functionality:
- `pending` specs got un-pended later, not written complete-and-passing from the start.
- Naive `if result.is_a? Success` checks got refactored to `case/in Success` pattern matching later, once the idiom had settled across several operations.
- A rake-file directory choice (`rakelib/`) got corrected two commits later once the "usual location" (`lib/tasks/`) became clear.
- `current_user` lookup logic landed in the wrong layer (View::Context) and got moved to the right one (Action) in an immediate follow-up.

Plan for this. Don't block progress on getting every layer's final idiomatic shape right before writing the first version — ship something that passes its own (possibly `pending`) tests, then follow up. That's what actually happened here, and it's a faster path than trying to design the perfect shape of every layer up front.
