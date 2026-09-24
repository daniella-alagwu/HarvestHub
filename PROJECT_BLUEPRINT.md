# HarvestHub — Project Blueprint (v1.0)


## 1. Architecture

```
Presentation Layer  →  Application Layer  →  Data Layer
 (Flutter UI,           (business rules,       (Firebase:
  role-based screens)    role-based access      Auth + Firestore)
                          control)
```

- **Database:** Firebase (Cloud Firestore + Firebase Authentication) —
  per the user's stated choice. 

## 2. Full Folder Structure

```
harvesthub/
├── android/
├── ios/
├── assets/
│   ├── images/
│   │   └── products/            # mock product images (fruits, veg, dairy…)
│   ├── icons/
│   │   ├── app_icon/            # launcher icon set (see LAUNCHER_ICON_SETUP.md)
│   │   └── app_icons/           # in-app iconography (category icons, nav icons)
│   └── splash_screen/           # logo layers + combined logo (see BRAND.md §4)
│
├── lib/
│   ├── main.dart                # entry point, Firebase init, MaterialApp
│   │
│   ├── presentation/            # ── UI TIER ──
│   │   ├── screens/
│   │   │   ├── splash/
│   │   │   │   ├── splash_screen.dart
│   │   │   │   └── animated_logo.dart
│   │   │   ├── auth/
│   │   │   │   ├── role_selection_screen.dart   # SRS 1.6: landing page accepts user role
│   │   │   │   ├── login_screen.dart
│   │   │   │   └── register_screen.dart         # customer registration form
│   │   │   ├── customer/
│   │   │   │   ├── home/product_catalog_screen.dart
│   │   │   │   ├── search/search_filter_screen.dart
│   │   │   │   ├── product/product_details_screen.dart
│   │   │   │   ├── wishlist/wishlist_screen.dart
│   │   │   │   ├── cart/shopping_cart_screen.dart
│   │   │   │   ├── checkout/checkout_screen.dart        # simulated checkout
│   │   │   │   ├── orders/order_history_screen.dart
│   │   │   │   ├── orders/order_detail_screen.dart
│   │   │   │   ├── pickup/pickup_slot_screen.dart
│   │   │   │   ├── farmers/farmer_profile_screen.dart   # follow/favorite
│   │   │   │   ├── assistant/ai_assistant_screen.dart   # AI Farm Products Assistant
│   │   │   │   ├── profile/customer_profile_screen.dart
│   │   │   │   ├── about/about_us_screen.dart
│   │   │   │   └── contact/contact_us_screen.dart
│   │   │   ├── farmer/
│   │   │   │   ├── dashboard/farmer_dashboard_screen.dart
│   │   │   │   ├── products/product_list_screen.dart
│   │   │   │   ├── products/add_edit_product_screen.dart
│   │   │   │   ├── inventory/inventory_management_screen.dart
│   │   │   │   ├── orders/farmer_orders_screen.dart      # view + update status
│   │   │   │   ├── reports/reports_screen.dart            # daily/weekly/monthly
│   │   │   │   └── profile/farmer_profile_screen.dart
│   │   │   └── admin/
│   │   │       ├── dashboard/admin_dashboard_screen.dart
│   │   │       ├── customers/manage_customers_screen.dart
│   │   │       ├── farmers/manage_farmers_screen.dart
│   │   │       ├── products/manage_products_screen.dart
│   │   │       ├── categories/manage_categories_screen.dart
│   │   │       ├── orders/manage_orders_screen.dart
│   │   │       └── reports/platform_reports_screen.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── text_styles.dart
│   │   │   └── colors/
│   │   │       ├── app_colors.dart
│   │   │       └── status_colors.dart
│   │   │
│   │   └── widgets/              # shared/reusable UI
│   │       ├── product_card.dart
│   │       ├── order_status_badge.dart
│   │       ├── primary_button.dart
│   │       ├── app_text_field.dart
│   │       └── empty_state.dart
│   │
│   ├── application/              # ── BUSINESS LOGIC TIER ──
│   │   ├── auth/auth_provider.dart
│   │   ├── cart/cart_provider.dart
│   │   ├── wishlist/wishlist_provider.dart
│   │   ├── orders/order_provider.dart
│   │   ├── products/product_provider.dart
│   │   ├── assistant/ai_assistant_service.dart
│   │   └── access_control/role_guard.dart      # role-based access control
│   │
│   └── data/                     # ── DATA TIER (Firebase) ──
│       ├── models/
│       │   ├── user_model.dart
│       │   ├── farmer_model.dart
│       │   ├── product_model.dart
│       │   ├── order_model.dart
│       │   └── market_model.dart
│       └── repositories/
│           ├── auth_repository.dart
│           ├── product_repository.dart
│           ├── order_repository.dart
│           └── farmer_repository.dart
│
├── test/
├── BRAND.md
├── PROJECT_BLUEPRINT.md
├── LAUNCHER_ICON_SETUP.md
└── pubspec.yaml
```

---

## 3. Screen Inventory by Role (traceable to SRS §1.6)

**Customer** — register/login, profile management, browse/search/filter,
product details, wishlist, cart, simulated checkout, order history,
pickup slot booking, farmer follow/favorite, AI Farm Products Assistant,
about us, contact us.

**Farmer** — secure login, profile management, add/update/delete
products, inventory updates (zero-stock items blocked from being
orderable), view + update order status, generate/view reports.

**Administrator** — manage customers, farmers, products, categories,
orders; view platform-wide reports (total orders, revenue summary across
markets, most active farmers). No sign-up — credentials preconfigured.

---

## 4. Firebase Schema (Firestore Collections)

Mirrors the SRS Database Design section exactly; `_Id` fields are
Firestore Document IDs, written here as PK/FK for readability.

```
users/{userId}
  name, email, role (customer|farmer), created_at

farmers/{farmerId}
  user_id (FK → users), market_id (FK → farmers_market),
  business_name, description, rating

products/{productId}
  farmer_id (FK → farmers), item_name, category,
  price_per_unit, stock_qty, image_url

orders/{orderId}
  customer_id (FK → users), farmer_id (FK → farmers),
  items_json, pickup_slot_time, status, total_price
  # status ∈ {Pending, Confirmed, Ready for Pickup, Completed, Cancelled}
  # → see status_colors.dart OrderStatus enum

farmers_market/{marketId}
  market_name, address, gps_coordinates,
  operating_hours, active_status
```

Recommended additions (not blocking, flagged for later):
- `wishlists/{userId}/items/{productId}` — subcollection per customer.
- `follows/{userId}/farmers/{farmerId}` — for the follow/favorite feature.

---

## 5. Explicit Constraints (SRS §1.5 — do not build these)

- No real payment gateway — checkout is simulated only.
- No delivery/logistics functionality — pickup only.
- Push notifications and recommendation systems are **out of scope for
  the core deliverable**, though the SRS's extended feature list
  describes them as desirable — treat as stretch goals, not baseline.

---

## 6. Build Order (suggested)

1. Firebase project setup + `flutterfire configure` → `firebase_options.dart`.
2. Theme lock-in (already scaffolded: `app_theme.dart`, `app_colors.dart`).
3. Splash → Role selection → Auth (login/register).
4. Customer flow: catalog → product details → cart → checkout → orders.
5. Farmer flow: dashboard → product/inventory management → order status.
6. Admin flow: management screens → platform reports.
7. AI Farm Products Assistant (predefined responses first; API integration
   optional per SRS).
8. Polish pass: pickup scheduling, farmer follow/favorite, reports.

---

## 7. Deliverables Checklist (SRS §1.9)

- [ ] Problem Definition
- [ ] Design Specifications
- [ ] Flowcharts / Data Flow Diagrams
- [ ] Database Design (this document, §4)
- [ ] Test Data
- [ ] Installation Instructions (mandatory)
- [ ] User Credentials for login (mandatory)
- [ ] Source code as a ZIP + ReadMe.doc (assumptions)
- [ ] Firestore collection schemas documented (no SQL — Firebase only)
- [ ] `.apk` or `.ipa` build included in the submission ZIP
- [ ] Demo video (`.mp4`) — mandatory
