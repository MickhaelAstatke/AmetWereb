# Remote Lyrics Backend

This project now expects a remote backend (Supabase, Firebase Functions, or your own REST API) to store the canonical set of lyric pages/sections and to serve signed audio URLs. The Flutter app still caches the data locally for offline use, but reads from and writes to the remote API whenever it is reachable.

## API shape

The default implementation assumes an HTTPS API with two endpoints:

| Method | Path      | Description |
| ------ | --------- | ----------- |
| `GET`  | `/pages`  | Returns `{ "pages": [LyricPageJson, ...] }` |
| `PUT`  | `/pages`  | Accepts `{ "pages": [LyricPageJson, ...] }` and replaces the current collection |
| `POST` | `/audio`  | Multipart upload that accepts the audio binary plus `pageId`/`sectionId` fields and returns `{ "url": "https://...", "duration": 123, "artist": "optional", "album": "optional" }` |

Set the base URL (and optional bearer token) at build time via `--dart-define=LYRICS_API_URL=...` and `--dart-define=LYRICS_API_KEY=...`. When no values are provided the client targets `http://localhost:8787` without authentication so you can run a local dev server during testing.

## Upload flow

When an editor selects an audio file inside the section dialog, the app now uploads it to the remote `/audio` endpoint. The backend must calculate the duration and return a signed URL that the player can stream later. The returned metadata is stored inside each `AudioMetadata` entry.

## Offline cache

The app still mirrors the remote collection to `ApplicationDocumentsDirectory/lyrics.json`. This file is read during startup when the network is unavailable, and every remote change writes through to the cache so the device can recover quickly after reconnecting.

## Seeding existing data

Run the helper script to push the bundled JSON (`assets/data/lyrics.json`) to your backend before rolling out the update:

```bash
# Customize the base URL or API key when needed
flutter pub run tool/seed_remote_lyrics.dart --base-url https://my-api.example.com --api-key superSecretToken
```

If you do not have Flutter available in your environment you can also invoke `dart run tool/seed_remote_lyrics.dart ...`. The script parses the same JSON the app ships with and calls the `/pages` endpoint once, so you can safely run it during migrations.
