# NaeemSoft-POS Architecture and Restructuring Plan

## Product scope
A single-location vegetable and fruit shop POS. This project is separate from the restaurant application and does not use multi-warehouse workflows.

## Architecture rules
- SQLite on-device remains the source of truth for stock, invoices, payments, and party balances.
- Inventory quantity is stored in grams; the UI may display kilograms and supplier-specific purchase packages.
- Inventory valuation uses weighted-average cost.
- Every posted purchase, sale, return, waste entry, or stock-count adjustment must write its source transaction and stock movement in one database transaction.
- Supplier settlements are independent account payments. They may be made at any time and in any amount; the supplier balance must decrease by the settlement amount.
- Do not delete historical business records. Archive master records that have been used in transactions.
- Arabic, English, and French must be supported from the application foundation, with RTL for Arabic and LTR for English/French.

## Target module boundaries
```
lib/
  app/                 # app bootstrap, navigation, theme, locale selection
  core/
    database/          # SQLite schema, migrations, transaction services
    localization/      # Arabic, English, French translations
    formatting/        # currency, quantity, date formatting
  features/
    products/          # product master data, categories, purchase/sale units
    inventory/         # stock balances, stock count, movement history, waste
    suppliers/         # supplier records and statements
    customers/         # customer records and statements
    purchases/         # purchase cashier, invoices, supplier returns
    sales/             # sales cashier, invoices, customer returns
    accounting/        # settlements, collections, allocations, balances
    reports/           # sales, purchases, profit, stock and account reports
  shared/
    widgets/           # reusable product grid, cart, keypad, dialogs
test/
  database/
  features/
```

## Current implementation checkpoint
- Existing database schema and application remain in their current locations while behavior is stabilized.
- A dedicated inventory center has been added in `lib/inventory_center.dart`.
- The center shows product count, total quantity, and inventory value.
- It supports physical stock counts and a movement-history view.
- Stock count changes are committed transactionally and recorded in `stock_movements`.
- Existing product create/edit/archive remains in the product management screen, opened from the inventory center.
- Automated tests have been added for positive and negative stock-count adjustments.

## Next implementation sequence
1. Validate the inventory center with Flutter tests, static analysis, and Android APK build.
2. Complete product master data: categories, purchase units, sale units, supplier-specific package weights, and safe archive rules.
3. Separate database services from UI and split the monolithic screen file into feature modules without changing existing business behavior.
4. Implement Arabic/English/French localization and direction switching across every screen, receipt, and report.
5. Complete purchase/sales flows, supplier settlements, customer collections, returns, and reconciled account statements.
6. Add stock reports, daily count reports, print/share output, and one-/two-month database scenario tests.

## Acceptance rules for inventory
- A stock count cannot create a negative quantity.
- An unchanged count creates no movement.
- An increased or decreased count creates exactly one adjustment movement.
- The inventory quantity and valuation update together.
- Sales cannot consume more stock than is available.
- Purchase and sale transactions must never be posted twice.
