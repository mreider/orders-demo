package com.dynatrace.ordersdemo.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;
import org.springframework.kafka.annotation.EnableKafka;

// Excluded under the "cloudrun" profile: Cloud Run runs the app standalone
// (no Kafka broker), so we disable Kafka entirely and keep only the HTTP
// surface for SDv2 endpoint detection.
@Configuration
@Profile("!cloudrun")
@EnableKafka
public class KafkaTopicConfig {
    @Bean
    public NewTopic orderEventsTopic() {
        return new NewTopic("order-events", 3, (short) 1);
    }
}
