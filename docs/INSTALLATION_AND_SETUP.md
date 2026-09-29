HarvestHub — Installation Guide

1. Prerequisites

Install a Flutter SDK compatible with the project's Dart constraint and a development environment such as Android Studio or Visual Studio Code. Tested and run correctly on JAVA 21 on the windows OS.

Also ensure:

Git is installed

A Firebase project is available

Android/iOS/Web platform tooling is configured for the target platform

2. Get the Project

Clone or extract the project and open the project root.

3. Install Dependencies

flutter pub get

4. Environment File

Create a .env file using the values documented in lib/.env.example.

Fill up with values from the .env.example

5. Firebase

Ensure the Firebase project configuration matches the generated firebase_options.dart and the target platforms.

Deploy or verify the Firestore rules and Firebase Functions as required for the development environment.

6. Run Static Analysis

flutter analyze

7. Run Tests

flutter test

8. Run the Application

flutter run

For Chrome:

flutter run -d chrome

9. Build Artifacts

The final submission should include the platform artifact required by the course instructions after the application has passed final testing.

The supplied SRS additionally requires a demonstration video and installation/user credential information in the submission package.
