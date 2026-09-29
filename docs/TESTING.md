HarvestHub — Testing Documentation

1. Current Test Stack

The project uses Flutter's flutter_test framework.

Current test files include:

test/register_screen_farmer_fields_test.dart
test/widget_test.dart

2. Existing Registration Test

register_screen_farmer_fields_test.dart verifies that the farmer registration form exposes a profile photo field and does not expose a separate farm photo field.

This reflects a recent implementation decision in the farmer registration workflow.

3. Default Flutter Test Still Needs Replacement

test/widget_test.dart currently contains the original Flutter counter smoke test. It should be replaced with HarvestHub-specific tests before final submission.

4. Recommended Test Categories

Authentication

Customer registration

Farmer registration

Login

Logout

Password reset

Role routing

Email verification behaviour

Customer

Product catalogue rendering

Search/filter behaviour

Product details

Wishlist state

Cart quantity validation

Out-of-stock protection

Checkout validation

Order history

Pickup-slot update

AI assistant fallback behaviour

Farmer

Product creation

Product editing

Product deletion

Stock adjustment

Low-stock display

Order filtering

Order status updates

Reports by time period

Farmer profile editing

Administrator

Permission-aware navigation

Customer management

Farmer management

Product/category management

Order management

Market management

Reports

Feedback/content management

Audit log visibility

Security

Security rules should be tested with authenticated users representing each role and with unauthenticated requests.

5. Manual Acceptance Testing

The final project should also include manual end-to-end testing using realistic test data.

Each test case should record:

Test ID
Feature
Precondition
Steps
Test Data
Expected Result
Actual Result
Pass/Fail
Notes