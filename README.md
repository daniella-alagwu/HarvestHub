# HarvestHub

HarvestHub is a Flutter marketplace backed by Firebase Authentication, Cloud Firestore, Cloud Storage, and a Firebase callable Cloud Function for checkout.

## Firebase backend

- Authentication manages email/password and Google sign-in accounts. User role and profile data live in `users/{uid}`; farmer storefront details live in `farmers/{uid}`.
- Products are stored in `products/{productId}`. Public catalog reads are supported; farmers can create and manage only their own listings.
- Checkout calls the `placeOrder` function in `functions/src/index.ts`. It verifies the authenticated customer, reads current product prices and stock, rejects invalid or unavailable items, decrements inventory, and creates one order per farmer in a single Firestore transaction. Prices and totals come from Firestore, not the submitted cart. A fixed $0.75 market fee is charged once per checkout.
- Orders are stored in `orders/{orderId}` and streamed by the customer and relevant farmer. Direct client order creation is denied by Firestore rules; status and pickup updates are limited to the parties involved.
- Markets use `farmers_market/{marketId}`; farmer dashboard alerts use `notifications/{notificationId}`. Product images are stored under `product_images/{farmerId}/` in Cloud Storage.
- Customer favorites and farmer follows are persisted in `wishlists/{uid}/items/{productId}` and `follows/{uid}/farmers/{farmerId}`.

## Deploy to the configured Firebase project

The app and Firebase CLI are configured for project `harvest-hub-d7d24`. Before deployment, make sure you have access to that Firebase project, have enabled Email/Password and Google providers in Authentication, and have created the Firestore database and Storage bucket. Deploying Cloud Functions requires the Firebase project to use the Blaze (pay-as-you-go) plan; Cloud Storage must also be initialized once in the Firebase Console.

1. In Firebase Console, set up Storage and upgrade the project to Blaze to enable Cloud Functions deployment.
2. Install the Firebase CLI and sign in with an account that has deploy access.
3. From the repository root, run `npm --prefix functions install`.
4. Run `firebase deploy --only firestore:rules,firestore:indexes,storage,functions`.
5. Run the Flutter app on a configured platform. Firebase client options are in `lib/firebase_options.dart`; Google sign-in also needs the platform OAuth client configuration. Optional local AI and Google server client values belong in the ignored `.env` file; never commit private server keys.

The first successful deployment is required before checkout can work because the app calls the deployed `placeOrder` function in `us-central1`. Deploying rules and storage only does not deploy the function.

## Local analysis

Run `flutter analyze` from the repository root to check the Flutter code. Build and deploy Cloud Functions with `npm --prefix functions run build` and the Firebase CLI command above.
