# Privacy Policy for PostPurush

**Last updated:** 30 September 2026

**Developer:** Gautam Rajeev Singh
**Application:** PostPurush for Android, a local-first API client

---

## 1. Overview

PostPurush is an API client. Its purpose is to send the HTTP requests you compose, so it
does use the network, and this policy is specific about what that means.

- **No account.** You do not register or sign in. There is nothing to sign in to.
- **No sync and no servers of ours.** PostPurush has no backend. We operate no service that
  receives your data, because there is no service.
- **No analytics, tracking or ads.** PostPurush contains no advertising SDK, no analytics
  SDK, no crash reporter and no attribution library.
- **Your data stays on your device.** Requests, collections, environments and history are
  stored in a private local database on your phone.

## 2. Network use

PostPurush makes exactly three kinds of outbound connection, and all three are ones you
start:

| When | What is sent | Where |
| :--- | :--- | :--- |
| You press Send, or run an assertion or load test | The request you composed: its URL, method, headers, query and body, with `{{variable}}` placeholders filled in from the environment you chose | The server whose URL you typed |
| You tap a documentation link in Explore or About | Nothing but the request for that page | The site the link points to, opened in your browser |
| You use Share | The text you chose to share | The app you pick in the Android share sheet |

Nothing else leaves the device. PostPurush does not check for updates, does not fetch a
remote configuration, does not report errors, and does not send a heartbeat. The Explore
catalogue of public APIs is bundled inside the app and works offline.

You are sending requests to third-party servers of your own choosing. Those servers see
your request and your IP address, and they operate under their own policies. PostPurush has
no relationship with them and cannot see or log what passes between you and them beyond
storing the response locally in your history, on your device.

## 3. What is stored on your device

All of this is local, in the app's private storage:

- Saved requests, folders and collections
- Environments and their variables, including any you marked secret
- Request history: the request as you composed it, the status, the timing, the size, the
  response headers and the response body
- Assertions saved with a request, and load-test settings
- Application preferences: theme, mode, true black, dynamic colour, timeout, default
  headers, redirect and certificate settings, time format, history retention

**Variables are never stored resolved.** A request, a history entry and an export all keep
`{{name}}` exactly as you typed it. Substitution happens at the moment of sending and the
resolved text is discarded afterwards. This is why a secret you keep in an environment does
not end up copied through your history.

**Secret variables** are masked in the interface, excluded from exports, and masked in a
generated code snippet or PDF unless you explicitly turn that off for one export.

**History retention.** History is kept for the period you choose in Settings (30 days by
default) and older entries are deleted automatically. You can clear it at any time. A
response body over 256 KB is not kept at all.

## 4. What is not collected

- No name, email address, postal address or phone number
- No location
- No advertising identifier, device fingerprint or installation identifier
- No usage statistics, no record of which features you open, no record of which APIs you
  call

Nothing is uploaded or backed up by PostPurush itself. Android's own backup service may
include the app's local data in your device backup, according to your Android settings.

## 5. Permissions

| Permission | Purpose |
| :--- | :--- |
| `android.permission.INTERNET` | To send the API requests you compose. This is the app's core function. |

No other permission is requested.

## 6. Certificate verification

Settings includes a switch to turn off TLS certificate verification. It exists so you can
test a local development server with a self-signed certificate. While it is off, a request
can be intercepted without warning you. Leave it on unless you are deliberately testing
such a server, and turn it back on afterwards.

## 7. Third-party services and SDKs

PostPurush integrates with no third-party analytics, advertising network or data broker.

It uses open-source Flutter and Dart libraries that run entirely on the device: `dio` for
HTTP, `drift` and `sqlite3` for local storage, `dynamic_color` for Material You theming,
`pdf` and `printing` for document export, and `share_plus` and `url_launcher` to hand
content to other apps you choose. None of them reports to us or to anyone else.

## 8. Children

PostPurush is a developer tool and is not directed at children. It collects no personal
information from anyone, of any age.

## 9. Your control over your data

- Delete any request, folder, environment or history entry from within the app.
- Clear all history from Settings.
- Uninstalling PostPurush removes its local database and every preference with it.

There is no account to close and no request to make of us, because we hold nothing.

## 10. Changes to this policy

If this policy changes, the updated version will ship with the app and the date above will
change. A change that would send data anywhere new would be described plainly here and in
the release notes.

## 11. Contact

Questions about this policy: gautamsingh1997@gmail.com
