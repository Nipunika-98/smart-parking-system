import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyB0-PX-my1Y4cquM66ZK2yvR7cvFFrXAwo",
  authDomain: "smartparkingsystem-e8234.firebaseapp.com",
  projectId: "smartparkingsystem-e8234",
  storageBucket: "smartparkingsystem-e8234.firebasestorage.app",
  messagingSenderId: "177916001676",
  appId: "1:177916001676:web:b6515932f4cd5b9cd7aaa9",
  measurementId: "G-C2F9VZY6Z2"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
