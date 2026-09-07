# Operation mode

The run's first gate, carried in the same message as the Orientation prose and before any target question. It asks how the operator wants to work. Recommend `supervised`.

Automated stays hidden only when every Configuration tool on the locked Integration path is Fit `none`, and then the skill explains why. An Uncataloged or Operator-only Prep step does not by itself hide automated. Until a path is locked, offer all three modes — the Lock has not happened yet and cannot take one away.

| Mode | What happens |
|---|---|
| `supervised` | The agent plans and discloses each change, then gates it. The operator runs the approved command in their own terminal and reports back; the agent verifies the non-secret result. The agent runs no mutation. |
| `automated` | The agent works the plan itself: before each cataloged Typed action it says what it is about to run, then runs it and verifies it — no per-change gate, and no command handed back. An Uncataloged Prep step takes one consent gate on the derived command and source, then the agent runs it. This includes a script that prints a secret; the agent keeps that output out of chat and the Connect log. Signing in stays the operator's, because only they hold the credentials. |
| `playbook` | The Connect log gets the whole safe write-up from the Typed actions — disclosures, targets, evidence checks, rollback or impact. No mutation runs; the operator executes later, on their own clock. No tool install, no auth-once. |

**Switching later:** under `supervised`, through the Prep gate's Adjust option, whose follow-up gate carries the remaining modes. Under `automated` there is no per-change gate, so the operator switches or stops by saying so — the agent does not pause to ask.

**Playbook-only batch:** several targets + playbook → one Connect log each with Lock and Intro; skip tools only. Supervised and automated stay sequential: finish one Lock before the next.
