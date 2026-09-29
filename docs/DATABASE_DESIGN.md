HarvestHub — Database Design

1. Database Technology

HarvestHub currently uses Firebase Cloud Firestore as its cloud database.

The application also uses Firebase Authentication for user identity and Firestore Security Rules for role-aware data access.

2. Core Collections

users

Stores application user accounts and role information.

Important fields observed in the current implementation include:

name
email
phone
address
role
active_status
email_verified
created_at
avatar_url

Roles currently used by the application include:

customer
farmer
admin

admins

Stores administrator profiles and permissions.

Important fields include:

name
email
level
permissions
active_status
created_by

Administrator levels currently include standard administrators and super administrators.

farmers

Stores farmer-specific profile and business information.

Important fields include:

user_id
business_name
market_id
market_location
description
rating
avatar_url
active_status
approval_status

products

Stores farmer product listings.

Important fields include:

farmer_id
item_name
description
category
price_per_unit
stock_qty
unit
image_url
is_organic
created_at

Some product records may also contain denormalized display information such as farmer or market information.

orders

Stores simulated customer orders.

Important fields include:

customer_id
farmer_id
items_json
pickup_slot_time
status
total_price
market_name
created_at

Supported order statuses in the current application are:

Pending
Confirmed
Ready for Pickup
Completed
Cancelled

farmers_market

Stores pickup/market information.

Important fields include:

market_name
address
gps_coordinates
operating_hours
active_status
pickup_slots

categories

Stores administrator-managed product categories.

notifications

Stores farmer-facing notification records and read/unread state.

Important fields include:

farmer_id
type
title
message
is_read
created_at

wishlists

Reserved for persistent customer wishlist storage using the pattern:

wishlists/{userId}/items/{productId}

The current WishlistProvider keeps active wishlist state locally and has not yet completed persistent Firestore wiring.

follows

Reserved for persistent farmer-follow state using the pattern:

follows/{userId}/farmers/{farmerId}

The current provider keeps follow state locally.

feedback

Stores feedback submitted by authenticated users and review information maintained by administrators.

settings

Stores application-level configuration. The current administrator repository uses settings/app for application settings.

app_content

Stores editable application content such as About/Contact content maintained through the administrator workspace.

audit_logs

Stores administrator activity records including action, target information, details, and timestamps.

3. Relationships

The principal relationships are:

users 1 ==== 0..1 farmers
users 1 ==== 0..1 admins
farmers 1 ==== many products
users 1 ==== many orders (customer_id)
farmers 1 ==== many orders (farmer_id)
farmers_market 1 ==== many pickup/order references
products 1 ==== many cart/order item references

4. Order Processing Relationship

At checkout, products are grouped by farmer. The server-side placeOrder function creates one order document per farmer represented in the cart.

This means a multi-farmer cart may create multiple order documents while retaining one overall checkout interaction for the customer.

5. Security Model

Firestore rules determine whether a request is allowed based on the authenticated user's role and ownership of a record.

Examples:

Customers can manage their own profiles and customer-owned orders.

Farmers can manage their own farmer profile, products, and farmer-owned orders.

Administrators can access platform management collections according to administrator permissions.

The complete implementation is defined in firestore.rules.