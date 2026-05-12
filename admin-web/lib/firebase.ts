import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyBtFF67Q1CgHW4x2qRRMAhahxXC4u2auRA",
  authDomain: "first-aid-app-7ae67.firebaseapp.com",
  projectId: "first-aid-app-7ae67",
  storageBucket: "first-aid-app-7ae67.firebasestorage.app",
  messagingSenderId: "221532503028",
  appId: "1:221532503028:web:01f85a90002e70efd257a1",
};

const app = initializeApp(firebaseConfig);

export const db = getFirestore(app);
