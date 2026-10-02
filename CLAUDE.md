# Project instructions

Shared rules for everyone (and every AI assistant) working on this Flutter app. General coding rules are in `AGENTS.md`.

## Desktop view app bar

Every screen must have a desktop view app bar.

- On desktop / big tablet (`ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isBigTab(context)`), show the shared `DashboardTopBar` (`lib/features/home/presentation/widgets/dashboard_top_bar.dart`) at the top of the body instead of the Material `AppBar`, and set `endDrawer: const WebProfileDrawer()`.
- On phone / small tablet keep the normal `AppBar`.
- Pass `navItems` with the main sections (Home, Meals, Deposits, Cost) and mark the current one `active: true`.
- A screen with no menu entry in the `DashboardTopBar` (e.g. Funds, Opinions) also keeps its title bar on desktop: put `WebPageTitleBar(title: ...)` (`lib/core/widgets/web_page_title_bar.dart`: common primary-colored bar, centered title, no back button) right under the `DashboardTopBar`, using the same title as the mobile `AppBar`. Show both bars in every state (loading, error, loaded), not only once data has loaded.
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

## Roles: the manager is also a member

A mess manager / acting manager (admin role) is also a regular member: they eat meals, deposit money and have their own balance.

- Every admin view must also show the manager's **own** data (my meals, my deposits, my balance), not only mess-wide or other members' data.
- On screens with admin and user branches (deposits, meals, costs, funds, home), never replace the personal "mine" view with the admin view — show both (e.g. admin overview + a "My …" section, or a "Mine" filter for admins).

## Error handling

Every error shown to the user must state the **specific** reason (e.g. "A user with this phone already exists.", "This mess has no active season."). A generic message ("Something went wrong") is only acceptable when the cause really can't be known (no response, unknown exception).

- Let the backend message flow through `DioExceptionX.toAppException` → `Failure.message` → UI (snack bar / error view). Don't replace it with hard-coded text in blocs or cubits; use a fallback only when the failure has no message.
- Don't swallow errors with `catch (_)` and show fixed text — show the real message.
- Form field errors from the backend go to the matching form field, not a generic toast.
- If a specific message needs a backend change, change the backend too (`mm_backend` is usually in the same workspace). If it isn't available, say exactly what the backend must change (endpoint, field, message) instead of hiding it in the app.

## Code organization

Keep every file organized; put new code where it belongs, never just appended to the nearest or last section.

- `AppConstants` endpoints: one commented section per feature (Config, Auth, Membership, Mess, Meals, Deposits, Funds, …); inside a feature, `— user` (`/api/v1/user`) before `— admin` (`/api/v1/admin`).
- `app_router.dart`: `AppRoutes` constants and `GoRoute`s grouped by feature.
- Feature files go in the matching layer: `data/datasources/{interfaces,remote,local}`, `data/models`, `domain/{entities,repositories,usecases}`, `presentation/{bloc,screens,widgets}`. One main widget/class per file, private helpers below it.
- In classes: fields → constructor → public methods → private helpers. No dead or duplicated code.
- When a file you touch is already disorganized, tidy the part related to your change and point out the rest.
