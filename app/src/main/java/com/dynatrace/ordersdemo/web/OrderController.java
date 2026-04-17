package com.dynatrace.ordersdemo.web;

import com.dynatrace.ordersdemo.domain.Order;
import com.dynatrace.ordersdemo.domain.OrderRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderRepository orders;
    private final KafkaTemplate<String, String> kafka;
    private final ObjectMapper json = new ObjectMapper();

    public OrderController(OrderRepository orders, KafkaTemplate<String, String> kafka) {
        this.orders = orders;
        this.kafka = kafka;
    }

    @PostMapping("/submit")
    public ResponseEntity<Map<String, Object>> submit(@RequestBody SubmitRequest req) throws Exception {
        // Strict endpoint: low-volume, tight latency envelope, small jitter.
        sleep(80, 180);

        UUID id = UUID.randomUUID();
        Order o = new Order(id, req.sku(), req.quantity(), "PENDING", Instant.now());
        orders.save(o);

        Map<String, Object> payload = Map.of(
                "orderId", id.toString(),
                "sku", req.sku(),
                "quantity", req.quantity(),
                "bad", req.bad()
        );
        kafka.send("order-events", id.toString(), json.writeValueAsString(payload));

        return ResponseEntity.status(201).body(Map.of("orderId", id.toString(), "status", "PENDING"));
    }

    @GetMapping("/search")
    public List<Order> search(@RequestParam String sku) {
        // Loose endpoint: wider latency envelope, occasional long tail (DB-heavy scan feel).
        int base = ThreadLocalRandom.current().nextInt(40, 200);
        int tail = ThreadLocalRandom.current().nextInt(100) < 5 ? 1500 : 0;
        sleep(base + tail, base + tail + 50);
        return orders.findTop50BySkuOrderByCreatedAtDesc(sku);
    }

    private static void sleep(int minMs, int maxMs) {
        try {
            Thread.sleep(ThreadLocalRandom.current().nextInt(minMs, Math.max(minMs + 1, maxMs)));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    public record SubmitRequest(String sku, int quantity, boolean bad) {}
}
