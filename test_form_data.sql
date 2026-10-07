-- Repeatable test fixtures for manually exercising HarvestHub forms.
-- All fixture records are labeled "Form Test" and use this password:
-- DemoPass123!

START TRANSACTION;

SET @form_test_hash = '$2y$10$M1CDgSTkuNnT/9aJCsoPjO41CUsnVHvsSpU6nu.zOnh7jx7E7F7LS';

INSERT INTO SYSTEM_ADMINISTRATOR (Name, Email, PasswordHash, Age, Location)
VALUES ('Form Test Admin', 'formtest.admin@harvesthub.test', @form_test_hash, 30, 'Manila')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), PasswordHash = VALUES(PasswordHash), Status = 'Active';

INSERT INTO GARDEN_COORDINATOR (Name, Email, PasswordHash, Shift, Location)
VALUES ('Form Test Coordinator', 'formtest.coordinator@harvesthub.test', @form_test_hash, 'Morning', 'Manila')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), PasswordHash = VALUES(PasswordHash), Status = 'Active';

INSERT INTO COMMUNITY_GARDENER (Name, Email, PasswordHash, Age, Location)
VALUES ('Form Test Gardener', 'formtest.gardener@harvesthub.test', @form_test_hash, 30, 'Manila')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), PasswordHash = VALUES(PasswordHash), Status = 'Active';

INSERT INTO COMMUNITY_GARDENER (Name, Email, PasswordHash, Age, Location)
VALUES ('Form Test Neighbor', 'formtest.neighbor@harvesthub.test', @form_test_hash, 31, 'Manila')
ON DUPLICATE KEY UPDATE Name = VALUES(Name), PasswordHash = VALUES(PasswordHash), Status = 'Active';

SET @form_test_gardener = (SELECT GardenerID FROM COMMUNITY_GARDENER WHERE Email = 'formtest.gardener@harvesthub.test');
SET @form_test_neighbor = (SELECT GardenerID FROM COMMUNITY_GARDENER WHERE Email = 'formtest.neighbor@harvesthub.test');

INSERT INTO PLOT (Label, GardenerID, Status)
SELECT 'Form Test Garden Plot', @form_test_gardener, 'Occupied'
WHERE NOT EXISTS (SELECT 1 FROM PLOT WHERE Label = 'Form Test Garden Plot');

INSERT INTO PLOT (Label, GardenerID, Status)
SELECT 'Form Test Application Plot', NULL, 'Available'
WHERE NOT EXISTS (SELECT 1 FROM PLOT WHERE Label = 'Form Test Application Plot');

SET @form_test_plt = (SELECT PltID FROM PLOT WHERE Label = 'Form Test Garden Plot' LIMIT 1);
SET @form_test_application_plt = (SELECT PltID FROM PLOT WHERE Label = 'Form Test Application Plot' LIMIT 1);

UPDATE PLOT SET GardenerID = @form_test_gardener, Status = 'Occupied' WHERE PltID = @form_test_plt;
UPDATE PLOT SET GardenerID = NULL, Status = 'Available' WHERE PltID = @form_test_application_plt;

INSERT INTO GARDEN_PLOTS (GardenerID, CropName, PlantedDate, EstHarvestDate, Status, Notes)
SELECT @form_test_gardener, 'Form Test Tomatoes', '2026-08-01', '2026-10-30', 'Growing', 'Form Test fixture: reset and validation testing.'
WHERE NOT EXISTS (SELECT 1 FROM GARDEN_PLOTS WHERE GardenerID = @form_test_gardener AND CropName = 'Form Test Tomatoes');

INSERT INTO GARDEN_PLOTS (GardenerID, CropName, PlantedDate, EstHarvestDate, Status, Notes)
SELECT @form_test_gardener, 'Form Test Basil', '2026-07-15', '2026-09-15', 'Harvested', 'Form Test fixture: exchange listing option.'
WHERE NOT EXISTS (SELECT 1 FROM GARDEN_PLOTS WHERE GardenerID = @form_test_gardener AND CropName = 'Form Test Basil');

INSERT INTO CROP_LOG (GardenerID, PltID, CropName, MaintenanceNotes, HarvestYield)
SELECT @form_test_gardener, @form_test_plt, 'Form Test Tomatoes', 'Form Test fixture: existing maintenance entry.', NULL
WHERE NOT EXISTS (SELECT 1 FROM CROP_LOG WHERE GardenerID = @form_test_gardener AND CropName = 'Form Test Tomatoes' AND MaintenanceNotes = 'Form Test fixture: existing maintenance entry.');

INSERT INTO PLOT_APPLICATION (GardenerID, PltID, Status, RequestType)
SELECT @form_test_neighbor, @form_test_application_plt, 'Pending', 'Apply'
WHERE NOT EXISTS (SELECT 1 FROM PLOT_APPLICATION WHERE GardenerID = @form_test_neighbor AND PltID = @form_test_application_plt AND Status = 'Pending');

INSERT INTO RESOURCE (Name, TotalQty, AvailableQty)
SELECT 'Form Test Seedling Tray', 12, 10
WHERE NOT EXISTS (SELECT 1 FROM RESOURCE WHERE Name = 'Form Test Seedling Tray');

SET @form_test_resource = (SELECT ResourceID FROM RESOURCE WHERE Name = 'Form Test Seedling Tray' LIMIT 1);

INSERT INTO RESOURCE_TXN (GardenerID, ResourceID, Qty, Status)
SELECT @form_test_gardener, @form_test_resource, 2, 'Requested'
WHERE NOT EXISTS (SELECT 1 FROM RESOURCE_TXN WHERE GardenerID = @form_test_gardener AND ResourceID = @form_test_resource AND Status = 'Requested');

INSERT INTO EXCHANGE_BOARD (GardenerID, ProduceName, Qty, Description, Type, Status)
SELECT @form_test_gardener, 'Form Test Tomatoes', '2 kg', 'Form Test fixture: your active listing and pending claim target.', 'Offering', 'Active'
WHERE NOT EXISTS (SELECT 1 FROM EXCHANGE_BOARD WHERE GardenerID = @form_test_gardener AND ProduceName = 'Form Test Tomatoes' AND Description LIKE 'Form Test fixture:%');

INSERT INTO EXCHANGE_BOARD (GardenerID, ProduceName, Qty, Description, Type, Status)
SELECT @form_test_neighbor, 'Form Test Basil', '3 bundles', 'Form Test fixture: claimable listing from another gardener.', 'Offering', 'Active'
WHERE NOT EXISTS (SELECT 1 FROM EXCHANGE_BOARD WHERE GardenerID = @form_test_neighbor AND ProduceName = 'Form Test Basil' AND Description LIKE 'Form Test fixture:%');

SET @form_test_own_post = (SELECT PostID FROM EXCHANGE_BOARD WHERE GardenerID = @form_test_gardener AND ProduceName = 'Form Test Tomatoes' AND Description LIKE 'Form Test fixture:%' ORDER BY PostID LIMIT 1);

INSERT INTO EXCHANGE_CLAIMS (PostID, RequesterID, QtyWanted, PickupDetails, Status)
SELECT @form_test_own_post, @form_test_neighbor, '1 kg', 'Form Test pickup: community garden entrance.', 'Pending'
WHERE NOT EXISTS (SELECT 1 FROM EXCHANGE_CLAIMS WHERE PostID = @form_test_own_post AND RequesterID = @form_test_neighbor AND Status = 'Pending');

INSERT INTO SIGNUP_REQUEST (FirstName, LastName, Age, Location, Email, PasswordHash, Role, Shift, Status)
SELECT 'Form Test', 'Signup', 28, 'Manila', 'formtest.signup@harvesthub.test', @form_test_hash, 'customer', 'Morning', 'Pending'
WHERE NOT EXISTS (SELECT 1 FROM SIGNUP_REQUEST WHERE Email = 'formtest.signup@harvesthub.test' AND Status = 'Pending');

COMMIT;
