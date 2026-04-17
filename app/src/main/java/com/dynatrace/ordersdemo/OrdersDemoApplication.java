package com.dynatrace.ordersdemo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.kafka.annotation.EnableKafka;

@SpringBootApplication
@EnableKafka
public class OrdersDemoApplication {
    public static void main(String[] args) {
        SpringApplication.run(OrdersDemoApplication.class, args);
    }
}
