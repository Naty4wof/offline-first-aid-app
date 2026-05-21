import { doc, getDoc } from "firebase/firestore";

import { db } from "@/lib/firebase";

export async function isAdminEmail(email?: string | null) {
  if (!email) return false;
  const normalized = email.trim().toLowerCase();
  const ref = doc(db, "admins", normalized);
  const snapshot = await getDoc(ref);
  return snapshot.exists();
}
