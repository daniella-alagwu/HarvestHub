import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";

initializeApp();
const db = getFirestore();
const MARKET_FEE = 0.75;

type RequestedItem = { productId: string; quantity: number };

export const placeOrder = onCall({ region: "us-central1", maxInstances: 20 }, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Sign in before placing an order.");

  const profile = await db.collection("users").doc(uid).get();
  if (profile.get("role") !== "customer") {
    throw new HttpsError("permission-denied", "Only customer accounts can place orders.");
  }

  const data = request.data as {
    items?: RequestedItem[];
    marketName?: string;
    pickupSlotTime?: number | null;
  };
  if (!Array.isArray(data.items) || data.items.length === 0 || data.items.length > 100) {
    throw new HttpsError("invalid-argument", "Add at least one product to your order.");
  }
  const seen = new Set<string>();
  const items = data.items.map((item) => {
    if (typeof item.productId !== "string" || !item.productId || seen.has(item.productId)
      || typeof item.quantity !== "number" || !Number.isFinite(item.quantity)
      || item.quantity <= 0 || item.quantity > 10000) {
      throw new HttpsError("invalid-argument", "One or more order quantities are invalid.");
    }
    seen.add(item.productId);
    return item;
  });
  const marketName = typeof data.marketName === "string" ? data.marketName.trim().slice(0, 120) : "";
  if (!marketName) throw new HttpsError("invalid-argument", "Choose a pickup market.");
  let pickupTime: Timestamp | null = null;
  if (data.pickupSlotTime != null) {
    if (typeof data.pickupSlotTime !== "number" || !Number.isFinite(data.pickupSlotTime)) {
      throw new HttpsError("invalid-argument", "The pickup time is invalid.");
    }
    pickupTime = Timestamp.fromMillis(data.pickupSlotTime);
  }

  const productRefs = items.map((item) => db.collection("products").doc(item.productId));
  const orderRefs = items.map(() => db.collection("orders").doc());
  return db.runTransaction(async (tx) => {
    const productSnaps = await Promise.all(productRefs.map((ref) => tx.get(ref)));
    const groups = new Map<string, { rows: Record<string, unknown>; subtotal: number }>();
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const snap = productSnaps[i];
      if (!snap.exists) throw new HttpsError("not-found", "A product in your cart is no longer listed.");
      const product = snap.data()!;
      const farmerId = product.farmer_id;
      const price = product.price_per_unit;
      const stock = product.stock_qty;
      if (typeof farmerId !== "string" || typeof price !== "number" || !Number.isFinite(price)
        || price < 0 || typeof stock !== "number" || !Number.isInteger(stock) || stock < 0) {
        throw new HttpsError("failed-precondition", "A product listing has invalid price or stock data.");
      }
      const stockNeeded = Math.ceil(item.quantity);
      if (stockNeeded > stock) {
        throw new HttpsError("failed-precondition", `${product.item_name ?? "A product"} has insufficient stock.`);
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
        created_at: FieldValue.serverTimestamp(),
      });
    }
    return {
      orderIds: orderRefs.slice(0, farmerGroups.length).map((ref) => ref.id),
      total: [...groups.values()].reduce((sum, group) => sum + group.subtotal, 0) + MARKET_FEE,
    };
  });
});
