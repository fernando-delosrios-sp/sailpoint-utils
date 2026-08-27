## ADDED Requirements

### Requirement: Log detail map term

The glossary SHALL define log detail map as the optional named key-value object passed as the second argument to ctx.log methods, serialized to the external log event detail field after redaction and JSON-safe normalization.

#### Scenario: log detail map used in specs

- **GIVEN** a spec or README describes structured ctx.log attachments
- **WHEN** referring to the second argument object
- **THEN** the preferred term SHALL be log detail map

---

### Requirement: JSON-safe detail normalization term

The glossary SHALL define JSON-safe detail normalization as the framework step that removes or replaces detail values that cannot be JSON-encoded before console formatting and logUrl POST.

#### Scenario: JSON-safe normalization used in specs

- **GIVEN** a spec describes detail handling before external POST
- **WHEN** referring to circular reference and function omission
- **THEN** the preferred term SHALL be JSON-safe detail normalization

---

### Requirement: Pretty console formatting term

The glossary SHALL define pretty console formatting as the multiline human-readable stdout layout for framework log events with a requestId headline and labeled detail blocks.

#### Scenario: pretty console formatting used in specs

- **GIVEN** a spec describes stdout layout for ctx.log
- **WHEN** referring to multiline per-key inspect output
- **THEN** the preferred term SHALL be pretty console formatting
