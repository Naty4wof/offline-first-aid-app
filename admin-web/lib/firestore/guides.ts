import {
  collection,
  getDocs,
  updateDoc,
  deleteDoc,
  doc,
  setDoc,
} from "firebase/firestore";

import { db } from "../firebase";
import { cacheFetch } from "./cache";

const guidesCollection = collection(db, "guides");

// ================= GET GUIDES =================

export async function getGuides(options?: {
  forceRefresh?: boolean;
  ttlMs?: number;
}) {
  const { forceRefresh = false, ttlMs } = options ?? {};

  return cacheFetch(
    "guides",
    async () => {
      const snapshot = await getDocs(guidesCollection);

      return snapshot.docs.map((docItem) => ({
        id: docItem.id,
        ...docItem.data(),
      }));
    },
    ttlMs,
    forceRefresh,
  );
}

// ================= UPDATE GUIDE =================

export async function updateGuide(id: string, data: Record<string, unknown>) {
  const guideDoc = doc(db, "guides", id);

  return await updateDoc(guideDoc, data);
}

// ================= DELETE GUIDE =================

export async function deleteGuide(id: string) {
  const guideDoc = doc(db, "guides", id);

  return await deleteDoc(guideDoc);
}

// ================= ADD GUIDE =================

export async function createGuide(
  id: string,
  data: Record<string, unknown>,
): Promise<void> {
  const guideDoc = doc(db, "guides", id);
  await setDoc(guideDoc, data);
}
