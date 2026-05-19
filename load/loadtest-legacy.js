import http from 'k6/http';
import { check } from 'k6';

const BASE = __ENV.BASE_URL || 'http://legacy-shop:8080';

// Volatile path generators. The IDs change per request, so without
// http.route on the Nginx server span, all of these collapse to a single
// endpoint (GET /*) until the SDv1 heuristic flag normalizes them.
// id() forces TWO leading digits (00..99) followed by six base36 chars.
// The SDv1 endpoint-naming heuristic templates these reliably; IDs that
// open with a single leading digit (or none) are skipped by the heuristic
// and leak through as per-URL endpoint rows.
function id()   {
  const twoDigits = Math.floor(Math.random() * 100).toString().padStart(2, '0');
  const rest = Math.random().toString(36).slice(2, 8);
  return twoDigits + rest;
}
function uuid() {
  return ([1e7] + -1e3 + -4e3 + -8e3 + -1e11).replace(/[018]/g, c =>
    (c ^ (Math.random() * 16) >> (c / 4)).toString(16));
}

export const options = {
  scenarios: {
    products: {
      executor: 'constant-arrival-rate',
      rate: 40, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 20, maxVUs: 40, exec: 'product',
    },
    cart_items: {
      executor: 'constant-arrival-rate',
      rate: 20, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 15, maxVUs: 30, exec: 'cartItem',
    },
    orders_lookup: {
      executor: 'constant-arrival-rate',
      rate: 10, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 10, maxVUs: 20, exec: 'orderLookup',
    },
    checkout: {
      executor: 'constant-arrival-rate',
      rate: 3, timeUnit: '1s', duration: __ENV.DURATION || '30m',
      preAllocatedVUs: 5, maxVUs: 10, exec: 'checkout',
    },
  },
  thresholds: { http_req_failed: ['rate<0.20'] },
};

export function product() {
  check(http.get(`${BASE}/shop/products/${id()}`), { '200': r => r.status === 200 });
}
export function cartItem() {
  check(http.get(`${BASE}/shop/carts/${uuid()}/items/${id()}`), { '200': r => r.status === 200 });
}
export function orderLookup() {
  check(http.get(`${BASE}/shop/orders/${uuid()}`), { '200': r => r.status === 200 });
}
export function checkout() {
  const body = JSON.stringify({ sku: 'SKU-1001', quantity: 1 });
  check(
    http.post(`${BASE}/shop/checkout`, body, { headers: { 'Content-Type': 'application/json' } }),
    { '20x': r => r.status === 200 || r.status === 201 },
  );
}
