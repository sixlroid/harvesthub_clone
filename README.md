# harvesthub_mysql
harvesthub with mysql database

For an existing database, apply `migrations/20261007_resource_lifecycle_events.sql` and then `migrations/20261007_plot_request_timeline.sql` once. Fresh installations get both event tables and the request processing timestamp from `schema.sql`. Lifecycle events are recorded from the migrations onward; older item additions cannot be backfilled because the previous schema did not store their timestamp or creator.

For an existing database, also apply `migrations/20261007_add_login_attempt_lockout.sql` once. It adds the `FailedLoginAttempts` column required by login; fresh installations already include it in `schema.sql`.

## Form testing data

Import `test_form_data.sql` into the existing `harvesthub` database (or select your app database in phpMyAdmin first). The fixture is safe to run again and adds clearly labeled Form Test accounts and records for plots, crops, inventory requests, exchange listings and claims, and pending reviews.

Use `DemoPass123!` for each test account:

- `formtest.admin@harvesthub.test`
- `formtest.coordinator@harvesthub.test`
- `formtest.gardener@harvesthub.test`
- `formtest.neighbor@harvesthub.test`

The gardener account has a harvested crop for testing the exchange listing form. The neighbor account has a pending plot application, a claimable listing, and is the requester on a pending claim for the gardener's own listing.
