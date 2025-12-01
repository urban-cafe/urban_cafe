# UrbanCafe

Flutter app (Material 3) with clean architecture and Provider that integrates with Supabase for menu management and image uploads. Targets mobile (iOS/Android) and web with responsive UI.

## Features
 - Public menu with search and category filter
 - Admin CRUD: create, edit, delete items
 - Image picker, optional crop, upload to Supabase Storage with public URL
 - Optional admin auth (email/password via Supabase Auth)
 - Clean Architecture: Presentation / Domain / Data
 - Unit tests for core use-cases and one widget test

## Folder Structure
```
lib/
  core/              # theme, env
  data/              # datasources, dtos, repositories
  domain/            # entities, repositories, usecases
  presentation/      # providers (ChangeNotifier) and screens/widgets
supabase/
  schema.sql         # table schema + seeds + policy hints
```

## Environment
Create `.env` in project root (or copy `.env.example`):
```
SUPABASE_URL=your_project_url
SUPABASE_ANON_KEY=your_anon_key
```

## Supabase Setup
1. Create a project at supabase.com and note `SUPABASE_URL` and `SUPABASE_ANON_KEY`.
2. Create a Storage bucket named `menu-images`.
3. Run SQL in `supabase/schema.sql` to create table and seed data. Adjust policies per your needs.
4. (Optional) Enable email/password auth and invite admin users.

### Storage Policy (example)
Allow authenticated upload to `menu-images` and public read:
```
-- See supabase/schema.sql for suggested policies
```

## Run
```
flutter pub get
flutter run
```
For web:
```
flutter run -d chrome
```

## Testing
```
flutter test
```

## Notes
- If `.env` is not configured, the app shows offline seed data for the public menu. Admin features will be disabled.
- Replace seed images with your own by uploading via admin and storing `image_url` from Storage.

