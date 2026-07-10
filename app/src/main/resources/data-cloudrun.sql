-- Seed inventory for the "cloudrun" profile (H2). Schema is created by
-- Hibernate (ddl-auto=create-drop); this runs after, so plain INSERTs suffice.
INSERT INTO inventory (sku, available) VALUES ('SKU-1001', 500);
INSERT INTO inventory (sku, available) VALUES ('SKU-1002', 1200);
INSERT INTO inventory (sku, available) VALUES ('SKU-1003', 75);
INSERT INTO inventory (sku, available) VALUES ('SKU-1004', 9999);
INSERT INTO inventory (sku, available) VALUES ('SKU-1005', 0);
