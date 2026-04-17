package com.dynatrace.ordersdemo.web;

import com.dynatrace.ordersdemo.domain.InventoryItem;
import com.dynatrace.ordersdemo.domain.InventoryRepository;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

@RestController
@RequestMapping("/inventory")
public class InventoryController {

    private final InventoryRepository inventory;

    public InventoryController(InventoryRepository inventory) {
        this.inventory = inventory;
    }

    @GetMapping("/check")
    public Map<String, Object> check(@RequestParam String sku) {
        // Fast endpoint: tight envelope, high volume.
        try {
            Thread.sleep(ThreadLocalRandom.current().nextInt(5, 25));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        InventoryItem item = inventory.findById(sku).orElse(new InventoryItem(sku, 0));
        return Map.of("sku", item.getSku(), "available", item.getAvailable());
    }
}
