import { collection, getDocs } from "firebase/firestore";
import { db } from "./firebase";
import { cacheFetch } from "./firestore/cache";

export async function getUsers(options?: {
  forceRefresh?: boolean;
  ttlMs?: number;
}) {
  const { forceRefresh = false, ttlMs } = options ?? {};

  return cacheFetch(
    "users",
    async () => {
      const snapshot = await getDocs(collection(db, "users"));

      return snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
    },
    ttlMs,
    forceRefresh,
  );
}
