# Project instructions

Shared rules for everyone (and every AI assistant) working on this Flutter app. General coding rules are in `AGENTS.md`.

## Desktop view app bar

Every screen must have a desktop view app bar.

- On desktop / big tablet (`ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)`), show the shared `DashboardTopBar` (`lib/features/home/presentation/widgets/dashboard_top_bar.dart`) at the top of the body instead of the Material `AppBar`, and set `endDrawer: const WebProfileDrawer()`.
- On phone / small tablet keep the normal `AppBar`.
- Pass `navItems` with the main sections (Home, Meals, Deposits, Cost) and mark the current one `active: true`.
- Reference implementation: `lib/features/cost/presentation/screens/cost_screen.dart`:

```dart
final showWebAppBar = ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context);

return Scaffold(
  endDrawer: showWebAppBar ? const WebProfileDrawer() : null,
  appBar: showWebAppBar ? null : AppBar(title: Text(...)),
  body: showWebAppBar
      ? Column(children: [DashboardTopBar(userName: ..., onProfileTap: () => Scaffold.of(context).openEndDrawer(), navItems: [...]), Expanded(child: body)])
      : body,
);
```

`Scaffold.of(context)` needs a context below the `Scaffold` (use a `Builder` or the body's own context).

## Routes

- Every screen has its own route: a constant in `AppRoutes` plus a `GoRoute` in `lib/config/route/app_router.dart`.
- Navigate with `context.push(AppRoutes.x)` / `context.go(AppRoutes.x)`, never `Navigator.push(MaterialPageRoute(...))` for a full screen.
- `main.dart` sets `GoRouter.optionURLReflectsImperativeAPIs = true` so pushed screens show in the web URL — keep it.
- Dialogs and bottom sheets don't need routes.

## Localization

The app supports English, Bengali and Arabic (`lib/l10n/arb/app_en.arb`, `app_bn.arb`, `app_ar.arb`; `app_en.arb` is the template).

- No hard-coded user-visible text in widgets: titles, labels, hints, buttons, snack bars, dialogs, validation messages, tooltips and `Semantics` labels all use `context.local.<key>`.
- Reuse an existing key when the meaning matches (e.g. `login`, `logout`, `settings`, `cancel`, `save`) instead of adding a near-duplicate.
- Add new keys **at the end** of all three ARB files, in the same order, with real translations (not English copies). Key names are lowerCamelCase.
- Run `flutter gen-l10n` after editing ARB files; generated files live in `lib/l10n/gen/` — don't edit them by hand.
- Build sentences with placeholders (`"welcome": "Welcome {name}"`), not string concatenation, so word order works in every language.
- Long translations must not break layouts: give `maxLines` + `TextOverflow.ellipsis` (or let text wrap) and check Bengali and Arabic (RTL) for overflow.

## Button labels

- Keep button text short (1–2 words) and meaningful so it fits in English, Bengali and Arabic — e.g. "Save", not "Save changes".
- Put longer explanations in titles, subtitles or dialog text, not on the button.
