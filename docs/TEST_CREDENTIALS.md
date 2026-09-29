# HarvestHub - Test Credentials

These accounts are for testing and evaluating the app. They were created only for this project, and they work with the Firebase project used for the submission.

## Accounts

| Role | Login (email) | Password | Notes |
| ---- | ------------- | -------- | ----- |
| Administrator | danielladevelops@gmail.com | Daniella123# | Preconfigured, no sign up. |
| Farmer 1 | ihannahekundayo@gmail.com | Hannah@28 | Has sample products and orders. |
| Farmer 2 | dfackt0808@gmail.com | code4life | Has no products or complete profile info. Freshly created |
| Customer 1 | tripledlovestequila@gmail.com | david1234 | Has previous orders. |
| Customer 2 | x7mystery7x@gmail.com | Olakitan123# | Fresh account, empty cart. |

## How to Log In

1. Open the app and choose a role on the landing page.
2. Enter the email and password from the table above.
3. Use the account that matches the role you selected, otherwise login will be refused.

## Suggested Things to Try

**Customer**
- Browse and search products
- Add a product to the cart and change the quantity
- Place an order with products from two different farmers
- Check the order history

**Farmer**
- Add, edit or delete a product
- Edit profile and stock availability
- Change a stock quantity
- Open the orders screen and update an order status
- Open the reports screen

**Administrator**
- Open the customer, farmer, product and order management screens
- Check the reports and the audit logs

## Test Data

| Item | Details |
| ---- | ------- |
| Sample products | <list a few, e.g. product name, category, price, stock> |
| Product with very low stock | <name> |
| Product with zero stock | <name> (used to test that it cannot be ordered) |
| Sample market | <market name> |

## Notes

- These are test accounts with dummy data only.
- No real payment is taken. Checkout is simulated.
- Farmer and customer accounts can also be created with the register screens.
- If the Farm Products Assistant (Flora) does not use Gemini, the `.env` file probably has no `GEMINI_API_KEY`. In that case it replies with the predefined answers.