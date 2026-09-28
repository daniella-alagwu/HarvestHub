"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.placeOrder = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const MARKET_FEE = 0.75;
exports.placeOrder = (0, https_1.onCall)({ region: "us-central1", maxInstances: 20 }, async (request) => {
    const uid = request.auth?.uid;
    if (!uid)
        throw new https_1.HttpsError("unauthenticated", "Sign in before placing an order.");
    const profile = await db.collection("users").doc(uid).get();
    if (profile.get("role") !== "customer") {
        throw new https_1.HttpsError("permission-denied", "Only customer accounts can place orders.");
    }
    const data = request.data;
    if (!Array.isArray(data.items) || data.items.length === 0 || data.items.length > 100) {
        throw new https_1.HttpsError("invalid-argument", "Add at least one product to your order.");
    }
    const seen = new Set();
    const items = data.items.map((item) => {
        if (typeof item.productId !== "string" || !item.productId || seen.has(item.productId)
            || typeof item.quantity !== "number" || !Number.isFinite(item.quantity)
            || item.quantity <= 0 || item.quantity > 10000) {
            throw new https_1.HttpsError("invalid-argument", "One or more order quantities are invalid.");
        }
        seen.add(item.productId);
        return item;
    });
    const marketName = typeof data.marketName === "string" ? data.marketName.trim().slice(0, 120) : "";
    if (!marketName)
        throw new https_1.HttpsError("invalid-argument", "Choose a pickup market.");
    let pickupTime = null;
    if (data.pickupSlotTime != null) {
        if (typeof data.pickupSlotTime !== "number" || !Number.isFinite(data.pickupSlotTime)) {
            throw new https_1.HttpsError("invalid-argument", "The pickup time is invalid.");
        }
        pickupTime = firestore_1.Timestamp.fromMillis(data.pickupSlotTime);
    }
    const productRefs = items.map((item) => db.collection("products").doc(item.productId));
    const orderRefs = items.map(() => db.collection("orders").doc());
    return db.runTransaction(async (tx) => {
        const productSnaps = await Promise.all(productRefs.map((ref) => tx.get(ref)));
        const groups = new Map();
        for (let i = 0; i < items.length; i++) {
            const item = items[i];
            const snap = productSnaps[i];
            if (!snap.exists)
                throw new https_1.HttpsError("not-found", "A product in your cart is no longer listed.");
            const product = snap.data();
            const farmerId = product.farmer_id;
            const price = product.price_per_unit;
            const stock = product.stock_qty;
            if (typeof farmerId !== "string" || typeof price !== "number" || !Number.isFinite(price)
                || price < 0 || typeof stock !== "number" || !Number.isInteger(stock) || stock < 0) {
                throw new https_1.HttpsError("failed-precondition", "A product listing has invalid price or stock data.");
            }
            const stockNeeded = Math.ceil(item.quantity);
            if (stockNeeded > stock) {
                throw new https_1.HttpsError("failed-precondition", `${product.item_name ?? "A product"} has insufficient stock.`);
            }
            const group = groups.get(farmerId) ?? { rows: {}, subtotal: 0 };
            group.rows[item.productId] = {
                item_name: String(product.item_name ?? "Product"),
                quantity: item.quantity,
                unit: String(product.unit ?? "item"),
                price_per_unit: price,
            };
            group.subtotal += price * item.quantity;
            groups.set(farmerId, group);
        }
        const farmerGroups = [...groups.entries()];
        for (let i = 0; i < items.length; i++) {
            tx.update(productRefs[i], { stock_qty: productSnaps[i].get("stock_qty") - Math.ceil(items[i].quantity) });
        }
        for (let i = 0; i < farmerGroups.length; i++) {
            const [farmerId, group] = farmerGroups[i];
            tx.create(orderRefs[i], {
                customer_id: uid,
                farmer_id: farmerId,
                items_json: group.rows,
                pickup_slot_time: pickupTime,
                status: "Pending",
                total_price: group.subtotal + (i === 0 ? MARKET_FEE : 0),
                market_name: marketName,
                created_at: firestore_1.FieldValue.serverTimestamp(),
            });
        }
        return {
            orderIds: orderRefs.slice(0, farmerGroups.length).map((ref) => ref.id),
            total: [...groups.values()].reduce((sum, group) => sum + group.subtotal, 0) + MARKET_FEE,
        };
    });
});
