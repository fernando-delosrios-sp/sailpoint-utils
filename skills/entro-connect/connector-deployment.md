# Connector deployment

A Connector is always required. Every Entro form carries a Worker Group (Connector) the operator picks from Connectors they already have, so this skill names the kind it has to be and leaves the picking to the form.

Hosting on the locked row (`public`, `self-hosted`, `operator-selected`) implies topology:

| Hosting | Topology to name |
|---|---|
| `public` | SaaS Perimeter |
| `self-hosted` | self-managed Docker Compose or Kubernetes Helm |
| `operator-selected` | Follow the form: public → SaaS Perimeter; self-hosted → Docker or Helm |

Name these options. Do not install or configure Docker, Helm, or SaaS Perimeter in this skill. Do not open `documentation/entro-connector/`.
