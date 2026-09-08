# Changelog

## 0.4.1 — Simpler saves & fixed editor dock

- Removed file encryption. Save files are now plain and easy to read/edit by hand.
- Fixed a bug where saved data could not be read back correctly in some cases. Old saves from previous versions now load fine too.
- The editor dock now shows the preferences your game actually saves, instead of an empty list.
- The dock updates itself automatically, so changes made while testing the game show up without pressing anything.
- Clicking a preference in the dock fills in the edit fields, so it is easy to tweak existing values.
- Export/Import dialogs now open in the same folder where the game stores its saves.

## 0.4.0 — Big feature update

- Multiple save slots / profiles.
- Save versioning with an automatic migration step for old saves.
- Choose when to save: after every change, manually, on a timer, or when the game closes.
- Export and import preferences as JSON files for easy debugging.
- New signals so your code can react to changes, deletions, clears, loads and slot switches.
- A new editor dock panel to inspect and edit preferences.
- Convenience getters for common types (int, float, bool, strings, vectors, colors, etc.).
- A large automated test suite to keep everything reliable.
