# HarvestHub

HarvestHub is a Flutter-based cross-platform marketplace that connects customers with local farmers and makes it easier to discover, compare, and purchase fresh agricultural products.

The project is based on the **HarvestHub Software Requirements Specification (SRS), Version 1.0**, prepared for the Multi-Platform App Computing project. The SRS describes HarvestHub as a marketplace with separate experiences for customers, farmers, and administrators, together with product discovery, simulated ordering, farmer management, reporting, and an AI Farm Products Assistant.

## Project Overview

HarvestHub provides a digital marketplace where customers can discover agricultural products and farmers, while farmers can manage their products, inventory, orders, and business information.

The current implementation uses:

* Flutter and Dart for the application
* Firebase Authentication for user authentication
* Cloud Firestore for application data
* Firebase Cloud Functions for trusted order creation
* Cloudinary for application image uploads
* Provider for application state management
* Google Gemini API with predefined fallback responses for the Farm Products Assistant
* Firebase Security Rules for role-aware database access

## User Roles

HarvestHub currently supports three main user roles.

### Customer

Customers can:

* Register and log in
* Manage their profile
* Browse agricultural products
* Search and filter products
* View product details
* View available stock
* Save products to a wishlist
* View farmer profiles
* Follow or favorite farmers during the active session
* Manage their shopping cart
* Update product quantities
* Complete simulated checkout
* View previous orders
* Update applicable pickup-slot information
* Use the Farm Products Assistant

Wishlist persistence and farmer-follow persistence have reserved Firestore structures, but the current providers primarily maintain these states locally during the active session.

### Farmer

Farmers can:

* Register and securely log in
* Manage their farmer profile
* Upload and update profile imagery
* Add products
* Edit products
* Delete products
* Set product categories
* Set prices and stock quantities
* Add product descriptions
* Manage product images
* Adjust inventory
* View customer orders
* Update order status
* View low-stock information
* View farmer notifications
* View daily, weekly, and monthly reports
* Use the farmer dashboard and navigation shell

Product and farmer profile image uploads currently use Cloudinary. Firebase Storage configuration remains in the project for compatibility with the Firebase setup, but the current upload implementation uses Cloudinary.

### Administrator

The administrator workspace provides platform-level management capabilities, including:

* Customer management
* Farmer management
* Product management
* Category management
* Order management
* Market management
* Reports
* Application content management
* About and Contact information
* Feedback management
* Audit logs
* Administrator controls and permissions

Administrative access is permission-aware and distinguishes administrator capabilities according to the configured admin profile and permissions.

## Main Features

### Product Marketplace

Customers can browse agricultural products and view information such as:

* Product name
* Category
* Price
* Available quantity
* Product image
* Farmer information
* Product description

The original SRS requires product browsing, category organization, search, filtering, and product details.

### Search and Filtering

The customer experience supports searching and filtering products by information including:

* Product name
* Category
* Farmer
* Market-related information where available
* Location and distance information where available

The SRS identifies product name, category, market name, location/distance, and farmer name as search/filter criteria.

### Shopping Cart

The shopping cart allows customers to:

* Add products
* Remove products
* Change quantities
* View subtotals
* Clear the cart
* Prepare items for simulated checkout

### Simulated Checkout and Orders

HarvestHub does not process real payments.

The checkout process creates simulated orders and records them in Firestore. The server-side `placeOrder` Firebase Function validates the authenticated customer, verifies product availability and stock, calculates the order values using authoritative Firestore data, updates inventory, and creates the corresponding order records.

For carts containing products from multiple farmers, the order-processing function groups products by farmer and creates the required farmer-specific order records.

This approach supports the SRS requirement that order placement be simulated rather than connected to a real payment gateway.

### Farmer Inventory

Farmers can manage product stock and update inventory quantities.

Products with very low stock can be identified through the farmer interface, supporting the SRS requirement for inventory monitoring and zero-stock ordering protection.

### Order Management

The farmer order workflow supports the order statuses used by the application:

```text
Pending
Confirmed
Ready for Pickup
Completed
Cancelled
```

These statuses correspond to the main order status flow specified in the SRS.

### Reports

Farmers can view report information across daily, weekly, and monthly periods.

The administrator workspace also provides platform-level reporting and management information.

The SRS explicitly identifies report generation as part of the farmer functionality.

### Farm Products Assistant

HarvestHub includes an in-app Farm Products Assistant for basic agricultural-product information.

The assistant can use the Gemini API when the required environment configuration is available. When external AI access is unavailable, predefined responses provide fallback assistance.

The assistant is intended for general informational topics such as:

* Fruits and vegetables
* Nutrition
* Storage
* Seasonal produce
* Basic farm-product questions

The SRS specifies that the assistant may use predefined responses or a basic AI API integration.

## Technology Stack

| Area                   | Technology                                           |
| ---------------------- | ---------------------------------------------------- |
| Application framework  | Flutter                                              |
| Programming language   | Dart                                                 |
| Authentication         | Firebase Authentication                              |
| Database               | Cloud Firestore                                      |
| Server-side processing | Firebase Cloud Functions                             |
| Image hosting/uploads  | Cloudinary                                           |
| State management       | Provider                                             |
| AI assistant           | Google Gemini API with predefined fallback responses |
| Networking             | `http`                                               |
| Local notifications    | `flutter_local_notifications`                        |
| Typography             | Google Fonts / Poppins                               |

The original SRS proposes Flutter, Firebase Authentication, Firebase/SQLite database support, and optional AI integration. The current implementation uses Flutter with Firebase and Cloudinary.

## Architecture

HarvestHub follows a layered application structure:

```text
Presentation Layer
        ↓
Application Layer
        ↓
Data / Repository Layer
        ↓
External Services
        ↓
Firebase / Cloudinary / Gemini
```

### Presentation Layer

Located primarily in:

```text
lib/presentation/
```

This layer contains:

* Screens
* Navigation
* Themes
* Reusable UI widgets

### Application Layer

Located in:

```text
lib/application/
```

This layer contains:

* Providers
* Application state
* Business-facing application logic
* Assistant logic
* Cart logic
* Order logic
* Wishlist logic

### Data Layer

Located in:

```text
lib/data/
```

This layer contains:

* Data models
* Repositories
* Static data
* Firebase-facing data operations
* Service adapters

### Firebase Functions

Located in:

```text
functions/
```

Server-side functionality such as trusted order creation is implemented here.

## Main Project Structure

```text
HarvestHub/
│
├── android/
├── ios/
├── linux/
├── macos/
├── windows/
├── web/
│
├── assets/
│   ├── icons/
│   ├── images/
│   └── splash_screen/
│
├── functions/
│   └── lib/
│       └── index.js
│
├── lib/
│   ├── application/
│   ├── core/
│   ├── data/
│   ├── presentation/
│   └── main.dart
│
├── test/
│
├── docs/
│   ├── README.md
│   ├── ACADEMIC_DOCUMENTATION_PLAN.md
│   ├── AI_USAGE_AND_ACKNOWLEDGEMENT.md
│   ├── DATABASE_DESIGN.md
│   ├── INSTALLATION.md
│   ├── PROJECT_STATUS.md
│   ├── REQUIREMENTS_TRACEABILITY.md
│   └── TESTING.md
│
├── BRAND.md
├── PROJECT_BLUEPRINT.md
├── firestore.rules
├── storage.rules
├── firebase.json
├── pubspec.yaml
└── README.md
```

## Firebase Collections

The current application uses Firestore collections including:

```text
users
admins
farmers
products
orders
farmers_market
categories
notifications
feedback
settings
app_content
audit_logs
wishlists
follows
```

The detailed database structure and relationships are documented separately in:

```text
docs/DATABASE_DESIGN.md
```

## Environment Configuration

The project uses environment variables for external services.

A reference configuration is maintained in:

```text
lib/.env.example
```

Current environment values include:

```text
GEMINI_API_KEY
CLOUDINARY_CLOUD_NAME
CLOUDINARY_UPLOAD_PRESET
```

Never commit real API keys, passwords, service credentials, or other secrets to source control.

## Firebase Configuration

Firebase configuration and security files are maintained through:

```text
firebase_options.dart
firebase.json
firestore.rules
storage.rules
```

Firebase is responsible for authentication, database storage, access control, and server-side functions.

Before running the project on a new development machine, the required Firebase project configuration must be available for the selected platform.

## Getting Started

From the project root, install dependencies:

```bash
flutter pub get
```

Check the project:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the application:

```bash
flutter run
```

For Chrome development:

```bash
flutter run -d chrome
```

## Order Processing

HarvestHub contains a callable Firebase Function named:

```text
placeOrder
```

The function is responsible for the trusted order-creation workflow.

At a high level it:

1. Authenticates the requesting user.
2. Confirms that the user is a customer.
3. Validates the requested cart items.
4. Reads authoritative prices and stock from Firestore.
5. Prevents orders that exceed available stock.
6. Groups products by farmer.
7. Updates stock inside the transaction.
8. Creates the corresponding order records.

The function implementation is located in:

```text
functions/lib/index.js
```

## Security

HarvestHub uses Firebase Security Rules and authenticated role information to control access to application data.

The main security files are:

```text
firestore.rules
storage.rules
```

The security model distinguishes between:

```text
customer
farmer
admin
```

Administrator permissions provide additional restrictions for protected administrative operations.

## Documentation

HarvestHub uses two levels of Markdown documentation.

### Root Documentation

These files provide project-wide reference information:

```text
README.md
BRAND.md
PROJECT_BLUEPRINT.md
```

### Detailed Documentation

The `docs/` folder contains technical, academic, testing, requirements, and project-management documentation:

```text
docs/
```

The documentation map is maintained in:

```text
docs/README.md
```

## Project Status

HarvestHub is an actively developed project and should be considered an implementation in progress until final testing and submission activities are complete.

Current documentation tracks:

* Implemented functionality
* Partially implemented functionality
* Reserved functionality
* Testing requirements
* Remaining documentation work
* Requirements that need final validation

See:

```text
docs/PROJECT_STATUS.md
docs/REQUIREMENTS_TRACEABILITY.md
```

## Academic Documentation

The SRS requires the project submission to include complete documentation covering areas such as:

* Problem definition
* Design specifications
* System diagrams
* Database design
* Test data
* Installation instructions
* User credentials
* Working demonstration material

The SRS also states that documentation is an important part of the project and that submitted documentation should not contain source code.

The supporting documentation for these requirements is maintained in:

```text
docs/
```

## AI Usage Acknowledgement

The SRS states that AI tools may be used as supporting aids for development and productivity, but the developer is expected to understand the implementation and acknowledge the AI tools used during the project.

HarvestHub maintains a record of AI-assisted development in:

```text
docs/AI_USAGE_AND_ACKNOWLEDGEMENT.md
```

This document should be updated whenever additional AI tools are used during the remainder of the project.

## Important Security Note

Do not commit any of the following to the repository:

```text
.env
real API keys
real passwords
private Firebase credentials
production secrets
```

Use example or placeholder credentials in documentation where necessary.

## License and Project Ownership

HarvestHub is an academic project developed for the Multi-Platform App Computing project requirements.

Project-specific branding, design decisions, application logic, and implementation should be treated as part of the project submission unless otherwise stated.

## Final Submission

Before final submission, the project should be accompanied by:

* Completed academic documentation
* Updated database documentation
* Requirements traceability
* Test cases and results
* Installation instructions
* Test credentials
* Application screenshots
* Demonstration video
* Final application build/package
* Source code and supporting project files

