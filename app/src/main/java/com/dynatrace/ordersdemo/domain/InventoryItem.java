package com.dynatrace.ordersdemo.domain;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "inventory")
public class InventoryItem {
    @Id
    private String sku;
    private int available;

    public InventoryItem() {}

    public InventoryItem(String sku, int available) {
        this.sku = sku;
        this.available = available;
    }

    public String getSku() { return sku; }
    public int getAvailable() { return available; }

    public void setSku(String sku) { this.sku = sku; }
    public void setAvailable(int available) { this.available = available; }
}
