## DartSketch

A experimental redux of the DartPad UI.

## Status?

This is an unofficial re-imagining of the DartPad UI. Some goals:

- re-write in Flutter Web
- keep the UI simple; make sure it's visually interesting
- keep the the number of use cases small; only Dart snippets and Flutter apps
  are supported

## How to run

To run this locally, run:

```
flutter run -d chrome
```

For development it's possible to run some aspects of the UI as a Flutter Desktop
app. Most text editing will not work and DartPad snippets will not execute.
However, this can still be useful for experimenting with smaller UI
modifications.

```
flutter run -d macos
```
