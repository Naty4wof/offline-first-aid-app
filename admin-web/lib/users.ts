import { collection, getDocs } from "firebase/firestore";
import { db } from "./firebase";

export async function getUsers() {
  const snapshot = await getDocs(collection(db, "users"));

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data(),
  }));
}