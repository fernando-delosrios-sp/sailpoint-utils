# Operator inputs

Collect after authentication. A live vendor session already knows the tenant, account, subscription, region, or org the operator would otherwise type, so asking first wastes their answers. Playbook mode has no session: collect from the catalog alone and mark every origin as operator-typed or catalog default.

## Which inputs the run needs

An input is in scope when the selected path uses it: a placeholder in a selected Typed action names it, or it `bindsTo` a Connection details field. An input nothing selected references stays unasked — an app display name matters when `az ad app create` runs it, not when a vendor script names the app itself.

Take the in-scope `operatorInputs` on the locked Integration path. Then read every `<placeholder>` in that path's Typed actions. Case tells them apart: `<snake_case>` names an input `key`, while `<camelCase>` is a value an earlier action produced (`<appId>` once the app exists) and belongs to that action. A `<snake_case>` placeholder with no matching `key` is a gap in the Skill catalog: stop and say which action needs which missing input. Never satisfy it with another input's value.

## One gate per input, purpose first

Every operator-supplied value arrives through a gate: one single-choice question-tool call per input, then a halt for the answer. A value only the operator holds — an org ID, an account number, a display name — is exactly what the call is for, so it reaches them as options they click or type over.

The gate's `prompt` carries the input's `purpose` — what the value names and where it ends up — before it asks for the value, because two inputs on one row can both be free text and mean entirely different things. An Entra app display name names an object created in the tenant; an Environment nickname is a label on the Entro form. Separate gates, separate answers.

Offer the suggestion from the session first: the Platform identity recorded in [tools.md](tools.md) (principal, endpoint, scope) and any read-only Typed action the catalog lists. Invent no lookup command. Catalog `default` is the fallback when the session says nothing.

Build each gate as follows:

- Put the session suggestion first and mark it recommended. When there is no session suggestion, offer the catalog default first and mark it recommended.
- The host supplies `Other`; tell the operator in the `prompt` to use it to enter a different value. Every option carries a real value, since an option reading "enter a value" supplies none when selected.
- When neither suggestion nor default exists, use `Help me find it` and `Stop the run` as the explicit options, and tell the operator to enter the value through `Other`. Help uses cataloged or authenticated-session facts first, then Context7 as [tools.md](tools.md) describes, then repeats the same input gate.
- Offer `Leave blank` only when the input is optional. An empty catalog default is a blank, not a recommendation to type an empty string.
- A required input stays on its own gate until it has a valid value or the operator stops the run.

**Reject a value only against a rule the platform enforces** — a 12-digit account id, an OCID prefix, a bucket-name pattern — and say which platform enforces it. A descriptive label takes whatever the operator typed: `validation` on those reads non-empty and nothing more, so a dot or a slash in a nickname is their choice, not an error.

**One value serves one `key`.** A value the operator gave for one input is never a suggestion for another. When the operator volunteers a value unprompted — a name for the app the run will create, say — name the input it belongs to and confirm it there.

**Worker Group (Connector) is not an input.** The operator selects it in the Entro form from Connectors they already have, so Connection details names the Connector kind the Integration requires instead of asking for one.

## Record

Persist `key` → value in the Connect log with its origin — derived from the session, catalog default, or operator-typed. Never persist a secret value; a secret-shaped input stays a named blank the operator fills in the Entro form.

**Done when:** every cataloged input for the Lock, and every input a selected Typed action's placeholder names, was resolved through its own gate and has a value or a stated blank in the Connect log, each carrying its origin.
