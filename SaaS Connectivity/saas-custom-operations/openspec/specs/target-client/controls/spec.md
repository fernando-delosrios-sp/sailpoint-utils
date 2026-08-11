# target-client/controls Specification

## Purpose

Generic controls API wrappers under `src/isc/controls/` for ISC APIs not yet exposed on bundled `sailpoint-api-client`. Modules SHALL NOT reference custom command names or operation-specific form field keys in their public API or requirements.

## Requirements

### Requirement: Compensating controls listing

The isc controls module SHALL list tenant compensating controls via pre-SDK HTTP transport, sending header `X-SailPoint-Experimental: true`.

#### Scenario: Controls listed

- **WHEN** a caller invokes `listControlsV1`
- **THEN** the client SHALL call `GET /controls/v1` with the experimental header
- **AND** SHALL return tenant compensating control records with id, name, and optional description
