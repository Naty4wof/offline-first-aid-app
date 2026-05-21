import {
  collection,
  deleteDoc,
  doc,
  getDocs,
  setDoc,
  updateDoc,
} from "firebase/firestore";

import { db } from "../firebase";
import { cacheFetch } from "./cache";

export type Injury = {
  id: string;
  categoryId: string;
  title: string;
  severity?: string;
  keywords?: string[];
};

const injuriesCollection = collection(db, "injuries");

export async function getInjuries(options?: {
  forceRefresh?: boolean;
  ttlMs?: number;
}): Promise<Injury[]> {
  const { forceRefresh = false, ttlMs } = options ?? {};

  return cacheFetch(
    "injuries",
    async () => {
      const snapshot = await getDocs(injuriesCollection);

      return snapshot.docs.map((docItem) => ({
        id: docItem.id,
        ...(docItem.data() as Omit<Injury, "id">),
      }));
    },
    ttlMs,
    forceRefresh,
  );
}

export async function createInjury(
  id: string,
  data: Omit<Injury, "id">,
): Promise<void> {
  const injuryDoc = doc(db, "injuries", id);
  await setDoc(injuryDoc, data);
}

export async function updateInjury(
  id: string,
  data: Partial<Omit<Injury, "id">>,
): Promise<void> {
  const injuryDoc = doc(db, "injuries", id);
  await updateDoc(injuryDoc, data);
}

export async function deleteInjury(id: string): Promise<void> {
  const injuryDoc = doc(db, "injuries", id);
  await deleteDoc(injuryDoc);
}
