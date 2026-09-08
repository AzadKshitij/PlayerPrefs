# Changelog

## 0.4.2 — Better editor dock

- The dock can now rename and delete save slots.
- Added a search box to quickly filter the preference list.
- Preferences now show their type (number, text, vector, bool, …) with a color hint.
- Added an Undo button to revert the last change made in the dock (edit, delete, clear or import).
- Fixed console errors triggered by typing in the filter and rename fields.
- The Refresh button now really reloads the save file from disk (the auto-refresh does too).
- The slot dropdown now switches on the first click and is no longer rebuilt while you are choosing.

New for game code:
- `rename_slot()` to rename a save slot from scripts.
- `restore_prefs()` to replace all preferences from a snapshot in one save.

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
