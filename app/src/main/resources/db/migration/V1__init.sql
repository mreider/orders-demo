CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY,
    sku VARCHAR(64) NOT NULL,
    quantity INT NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_orders_sku_created ON orders (sku, created_at DESC);

CREATE TABLE IF NOT EXISTS inventory (
    sku VARCHAR(64) PRIMARY KEY,
    available INT NOT NULL
);

INSERT INTO inventory (sku, available) VALUES
    ('SKU-1001', 500),
    ('SKU-1002', 1200),
    ('SKU-1003', 75),
    ('SKU-1004', 9999),
    ('SKU-1005', 0)
ON CONFLICT (sku) DO NOTHING;
