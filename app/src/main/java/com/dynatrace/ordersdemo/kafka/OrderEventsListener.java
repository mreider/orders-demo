package com.dynatrace.ordersdemo.kafka;

import com.dynatrace.ordersdemo.domain.InventoryItem;
import com.dynatrace.ordersdemo.domain.InventoryRepository;
import com.dynatrace.ordersdemo.domain.Order;
import com.dynatrace.ordersdemo.domain.OrderRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;

@Component
public class OrderEventsListener {

    private static final Logger log = LoggerFactory.getLogger(OrderEventsListener.class);

    private final OrderRepository orders;
    private final InventoryRepository inventory;
    private final ObjectMapper json = new ObjectMapper();

    public OrderEventsListener(OrderRepository orders, InventoryRepository inventory) {
        this.orders = orders;
        this.inventory = inventory;
    }

    @KafkaListener(topics = "order-events", groupId = "orders-demo")
    @Transactional
    public void onOrderEvent(String raw) throws Exception {
        // Realistic consumer latency: DB read + DB write + some thinking.
        Thread.sleep(ThreadLocalRandom.current().nextInt(30, 120));

        JsonNode msg = json.readTree(raw);
        UUID orderId = UUID.fromString(msg.get("orderId").asText());
        String sku = msg.get("sku").asText();
        int qty = msg.get("quantity").asInt();
        boolean bad = msg.get("bad").asBoolean();

        // Seeded failure: bad payloads throw and mark the transaction failed.
        // Produces the HTTP-submit-succeeded-but-Kafka-consume-failed seam
        // surfaced in the demo notebook's messaging-family queries.
        if (bad) {
            log.warn("Rejecting bad order {}", orderId);
            throw new IllegalStateException("bad order payload: " + orderId);
        }

        InventoryItem item = inventory.findById(sku).orElse(new InventoryItem(sku, 0));
        int newAvail = Math.max(0, item.getAvailable() - qty);
        item.setAvailable(newAvail);
        inventory.save(item);

        Order o = orders.findById(orderId).orElseThrow();
        o.setStatus(newAvail > 0 ? "FULFILLED" : "BACKORDERED");
        orders.save(o);
    }
}
