# CMTAT-Canton

CMTAT core mandatory implementation for Canton/Daml.

## Repository Structure
- `cmtat-canton/`: Daml package implementing CMTAT core mandatory features.
- `CMTAT-equivalency-assessment/`: assessment checklist and mapping material.
- `CMTAT_GUIDELINE.md`: implementation guideline used for this Canton version.

## Quick Start
From repository root:

```bash
make daml-build-docker
make daml-test-docker
```

The Docker targets are defined in [Makefile](/home/ryan/Pictures/dev/CMTAT-Canton/Makefile) and run `daml` inside `digitalasset/daml-sdk:2.9.5`.

## Detailed Documentation
Implementation details, CMTAT requirement mapping, and test coverage are documented in:
- [cmtat-canton/README.md](/home/ryan/Pictures/dev/CMTAT-Canton/cmtat-canton/README.md)
