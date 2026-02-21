# Urban Cafe v2.0.0 — Release Notes

**Release Date:** February 21, 2026
**Tag:** `v2.0.0-full`
**Flutter SDK:** ^3.11.0

---

## Overview

This is the **full-featured** version of Urban Cafe before production optimization and feature trimming. This tag preserves ALL features for future reference or restoration.

---

## Features Included

### 🔐 Authentication
- Email/Password sign-up & login
- Google Sign-In (OAuth)
- Anonymous guest browsing
- Email confirmation flow
- Role-based access (admin, staff, client)

### 📋 Digital Menu
- Category browsing (main + sub-categories)
- Menu item grid & list views
- Item detail with variants and add-ons
- Favorites system (per-user)
- Search & filter (All, Cold, Hot)
- Animated card interactions

### 🛒 Cart & Ordering
- Add items to cart with customization
- Order placement (dine-in / takeaway)
- Client order history
- Order status tracking

### 📊 Admin Dashboard
- Menu item CRUD (create, edit, delete)
- Category management (create, rename, delete)
- Admin analytics with charts
- QR code scanner for loyalty
- Staff order management
- Image upload with compression

### 💎 Loyalty Points
- QR-based point earning
- Point token generation & redemption
- Loyalty transaction history
- Admin point settings configuration

### 🏪 POS (Point of Sale)
- Offline-capable order creation
- SQLite local storage
- Order sync to Supabase
- Cash/card payment tracking

### 👤 Profile
- Edit profile (name, phone, address)
- Language selection
- Theme customization
- Contact us page
- Order history view
- Favorites view

---

## Technical Architecture

### Stack
- **Frontend:** Flutter 3.11 (iOS, Android, Web, macOS)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, RLS)
- **CDN:** Cloudflare Workers (image caching proxy)
- **CI/CD:** GitHub Actions → Cloudflare Pages, Vercel, GitHub Pages

### Database Tables (Supabase)
| Table | Rows | Purpose |
|---|---|---|
| `profiles` | 63 | User profiles & roles |
| `menu_items` | 118 | Menu catalog |
| `categories` | — | Menu categories (hierarchical) |
| `favorites` | 11 | User favorites |
| `menu_item_variants` | 6 | Item size/type variants |
| `menu_item_addons` | 8 | Item add-ons |
| `orders` | 13 | Orders |
| `order_items` | 28 | Order line items |
| `order_logs` | — | Order status history |
| `payments` | — | Payment records |
| `loyalty_transactions` | 12 | Points earned/redeemed |
| `point_tokens` | 44 | QR point tokens |
| `point_settings` | 1 | Points configuration |

### Key Dependencies
| Package | Version | Purpose |
|---|---|---|
| `supabase_flutter` | ^2.10.3 | Backend |
| `go_router` | ^17.1.0 | Navigation |
| `provider` | ^6.1.5 | State management |
| `get_it` | ^9.2.0 | Dependency injection |
| `cached_network_image` | ^3.4.1 | Image caching |
| `sqflite` | ^2.4.2 | Local SQLite |
| `mobile_scanner` | ^7.2.0 | QR scanning |
| `fl_chart` | ^1.1.1 | Analytics charts |
| `image` | ^4.8.0 | Image compression |

### Image Optimization
- Uploaded images are compressed to 800px max, 75% quality JPG
- Cloudflare Workers CDN caches images with 1-year TTL
- Reduces Supabase egress by serving from edge cache

---

## Setup Instructions (Restoring This Version)

```bash
# 1. Clone and checkout the tag
git clone <repo-url>
git checkout v2.0.0-full

# 2. Create .env file
cat > .env << EOF
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
CDN_URL=https://your-cdn-worker.workers.dev
EOF

# 3. Install and run
flutter pub get
flutter run
```

---

## Known Issues
1. **ISP blocking:** Some Myanmar ISPs block `*.workers.dev` domains, causing mobile image loading failures. Fix: use a custom domain for the CDN Worker.
2. **Large images:** Existing uploaded images (pre-compression) are 2.5-3.5MB. New uploads are now compressed to ~200KB.
3. **Cached Egress:** Supabase cached egress exceeded 5GB free tier (6.234/5 GB at time of release).

---

## Next Version (v3.0.0)
- Remove Cart, Orders, POS features
- Keep Auth, Profile, Menu, Loyalty, Admin
- Add offline-first menu cache (SQLite)
- Optimize API requests and DB queries
- Production-ready release
