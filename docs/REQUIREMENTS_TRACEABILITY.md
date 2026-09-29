HarvestHub — SRS Requirements Traceability

This document maps the supplied HarvestHub SRS to the current project implementation, showing how requirements were implemented.

Status values:

Implemented — functionality is present in the current source tree.

Partial — a working foundation exists, but the full SRS behaviour is not yet complete.

Planned — identified in the SRS/project design but not currently implemented as a complete feature.

Customer Requirements

SRS Requirement

Status

Current Evidence

Customer registration and login

Implemented

register_screen.dart, auth_repository.dart, login_screen.dart

Customer profile management

Implemented

customer_profile_screen.dart, edit_profile_screen.dart

Browse products

Implemented

product_catalog_screen.dart, product_provider.dart

Search products

Implemented

search_screen.dart, product_provider.dart

Category filtering

Implemented

category_filter_row.dart, product_provider.dart

Product details

Implemented

product_details_screen.dart

Wishlist

Partial

Local session provider is implemented; persistent Firestore storage remains reserved

Shopping cart

Implemented

cart_provider.dart, shopping_cart_screen.dart

Simulated checkout

Implemented

Customer checkout flow + callable placeOrder function

Order history

Implemented

order_provider.dart, order_history_screen.dart

Pickup-slot management

Partial/Implemented foundation

Market and pickup-slot models plus customer slot updates are present; full cancellation workflow should be revalidated

AI Farm Products Assistant

Implemented

ai_assistant_screen.dart, ai_assistant_service.dart

Farmer follow/favorite

Partial

Local session state exists in WishlistProvider; persistence remains open

Restock alerts

Partial

Farmer notification generation exists; customer restock push delivery is not fully wired

Customer push notifications

Planned/Partial

Notification records exist; full customer push delivery requires further integration

Farmer Requirements

SRS Requirement

Status

Current Evidence

Farmer registration/login

Implemented

register_screen.dart, auth_repository.dart

Farmer profile management

Implemented

farmer_profile_screen.dart, farmer_edit_profile_screen.dart

Add products

Implemented

farmer_add_product_screen.dart, farmer_dashboard_repository.dart

Update products

Implemented

farmer_products_screen.dart, repository update logic

Delete products

Implemented

Farmer inventory/repository logic

Inventory management

Implemented

Stock adjustment and live product streams

Zero-stock ordering protection

Implemented

functions/lib/index.js checks stock before creating orders

View customer orders

Implemented

farmer_orders_screen.dart

Update order status

Implemented

Farmer order status update logic

Notifications

Partial

Farmer notification stream and low-stock/pending-order creation are present

Daily/weekly/monthly reports

Implemented

farmer_reports_screen.dart

Administrator Requirements

SRS Requirement

Status

Current Evidence

Administrator authentication/access

Implemented

AdminProfile, AdminRepository, Firestore rules

Manage customers

Implemented

Admin workspace and repository

Manage farmers

Implemented

Admin workspace and repository

Manage products

Implemented

Admin workspace and repository

Manage categories

Implemented

Admin workspace and repository

Manage orders

Implemented

Admin workspace and repository

Platform-wide reports

Implemented

watchDashboardReport() and admin dashboard reporting

Market management

Implemented

Admin market management support

Content management

Implemented

app_content support

Feedback management

Implemented

feedback and admin support

Audit logs

Implemented

audit_logs and admin repository

Non-Functional Requirements

SRS Requirement

Current Approach

Performance

Flutter UI, live streams, layered architecture; further profiling remains part of final testing

Security

Firebase Authentication, Firestore Security Rules, role-aware access checks

Scalability

Cloud Firestore and server-side callable order creation provide a scalable backend foundation

Accessibility

Legible typography, visible UI states, reusable text styles and navigation components

Reliability

Error handling and fallback logic exist in authentication, AI assistant, and image upload paths; broader reliability testing is still required

Data backup

Not documented as an implemented scheduled backup process in the current source tree