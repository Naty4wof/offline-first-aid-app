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

export type Category = {
  id: string;
  name: string;
  description?: string;
};

const categoriesCollection = collection(db, "categories");

export async function getCategories(options?: {
  forceRefresh?: boolean;
  ttlMs?: number;
}): Promise<Category[]> {
  const { forceRefresh = false, ttlMs } = options ?? {};

  return cacheFetch(
    "categories",
    async () => {
      const snapshot = await getDocs(categoriesCollection);

      return snapshot.docs.map((docItem) => ({
        id: docItem.id,
        ...(docItem.data() as Omit<Category, "id">),
      }));
    },
    ttlMs,
    forceRefresh,
  );
}

export async function createCategory(
  id: string,
  data: Omit<Category, "id">,
): Promise<void> {
  const categoryDoc = doc(db, "categories", id);
  await setDoc(categoryDoc, data);
}

export async function updateCategory(
  id: string,
  data: Partial<Omit<Category, "id">>,
): Promise<void> {
  const categoryDoc = doc(db, "categories", id);
  await updateDoc(categoryDoc, data);
}

export async function deleteCategory(id: string): Promise<void> {
  const categoryDoc = doc(db, "categories", id);
  await deleteDoc(categoryDoc);
}
