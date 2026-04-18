import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE = __ENV.BASE_URL || 'http://orders-demo:8080';
const SKUS = ['SKU-1001', 'SKU-1002', 'SKU-1003', 'SKU-1004', 'SKU-1005'];

export const options = {
  scenarios: {
    inventory_hot: {
      executor: 'constant-arrival-rate',
      rate: 70, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 30, maxVUs: 60, exec: 'inventoryCheck',
    },
    orders_search: {
      executor: 'constant-arrival-rate',
      rate: 25, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 20, maxVUs: 40, exec: 'ordersSearch',
    },
    orders_submit: {
      executor: 'constant-arrival-rate',
      rate: 5, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 10, maxVUs: 20, exec: 'ordersSubmit',
    },
  },
  thresholds: {
    // Soft thresholds - we want traffic to keep flowing even if the app wobbles.
    http_req_failed: ['rate<0.20'],
  },
};

function pickSku() {
  return SKUS[Math.floor(Math.random() * SKUS.length)];
}

export function inventoryCheck() {
  const res = http.get(`${BASE}/inventory/check?sku=${pickSku()}`);
  check(res, { 'inventory 200': r => r.status === 200 });
}

export function ordersSearch() {
  const res = http.get(`${BASE}/orders/search?sku=${pickSku()}`);
  check(res, { 'search 200': r => r.status === 200 });
}

export function ordersSubmit() {
  // 2% of submits are seeded as "bad" - the Kafka consumer will reject them.
  // This produces the HTTP-submit-OK-but-Kafka-consume-fails seam used in
  // the demo notebook's messaging-family queries.
  const bad = Math.random() < 0.02;
  const body = JSON.stringify({
    sku: pickSku(),
    quantity: Math.floor(Math.random() * 5) + 1,
    bad,
  });
  const res = http.post(`${BASE}/orders/submit`, body, {
    headers: { 'Content-Type': 'application/json' },
  });
  check(res, { 'submit 201': r => r.status === 201 });
}
