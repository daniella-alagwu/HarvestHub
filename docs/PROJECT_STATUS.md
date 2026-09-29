HarvestHub — Project Status

1. Current State

HarvestHub is an actively developed Flutter/Firebase marketplace application with working customer, farmer, and administrator modules.

The repository has moved beyond the original Flutter starter template and now includes:

Firebase authentication

Firestore-backed marketplace data

Customer shopping flow

Farmer inventory & order management

Administrator management workspace

Cloudinary image uploads

Firebase Cloud Functions for trusted order creation

Gemini-backed Farm Products Assistant with fallback responses

Role-aware Firestore security rules

2. Working Areas

Customer

The principal customer flow is implemented from authentication through catalogue, search, product details, cart, simulated order creation, order history, profile, and assistant access.

Farmer

The principal farmer flow is implemented through dashboard, inventory, products, orders, reports, notifications, and profile management.

Administrator

The administrator workspace provides platform-level management and reporting capabilities through a permission-aware dashboard.

3. Areas Requiring Final Validation

These should be explicitly tested before final submission:

All registration paths on Android/web.

Firebase role routing after login.

Product creation, editing, image upload, stock adjustment, and deletion.

Multi-farmer cart order creation.

Stock depletion and zero-stock prevention.

Order status transitions.

Farmer profile editing and image upload.

Admin permissions and restricted sections.

Firestore Security Rules with real authenticated roles.

Gemini assistant behaviour with and without an API key.

Responsive behaviour on mobile-size layouts.

Real device testing for authentication and image upload.

4. Known Documentation/Testing Tasks

Replace the default Flutter counter smoke test with HarvestHub-specific widget/integration tests.

Document representative test data.

Document installation from a clean machine.

Record all user test accounts safely without committing real passwords to the repository.

Produce diagrams required by the SRS.

Capture screenshots of major user flows for the final report.

Create and record the mandatory demonstration video.

Confirm final application package generation for the target submission platform.