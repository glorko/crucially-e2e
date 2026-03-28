# E2E repo documentation

## `maestro/` (vendored Maestro docs)

The Markdown files under [maestro/](maestro/) are **offline snapshots** of Maestro’s public documentation, generated for quick reference without hitting the network.

**Refresh** (from this `docs/` directory):

```bash
python3 download_maestro_docs.py
```

Upstream docs live at [maestro.mobile.dev](https://maestro.mobile.dev/) / [docs.maestro.dev](https://docs.maestro.dev/).

## Other scripts

- [strip_html.py](strip_html.py) — helper used when processing downloaded pages.
