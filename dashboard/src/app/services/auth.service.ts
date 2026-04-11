import { Injectable, inject } from '@angular/core';
import { Router } from '@angular/router';
import { auth, db } from '../firebase.config';
import { signInWithEmailAndPassword, signOut, onAuthStateChanged, User } from 'firebase/auth';
import { doc, getDoc, query, collection, where, getDocs } from 'firebase/firestore';
import { BehaviorSubject, Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private router = inject(Router);
  private userSubject = new BehaviorSubject<User | null>(null);
  user$: Observable<User | null> = this.userSubject.asObservable();
  
  private authInitialized = new BehaviorSubject<boolean>(false);
  authInitialized$ = this.authInitialized.asObservable();

  constructor() {
    onAuthStateChanged(auth, (user) => {
      this.userSubject.next(user);
      if (!this.authInitialized.value) {
        this.authInitialized.next(true);
      }
    });
  }

  async login(email: string, password: string): Promise<{ success: boolean; message?: string }> {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // 1. Try checking by UID (standard)
      const adminDocRef = doc(db, 'admins', user.uid);
      const userDocRef = doc(db, 'users', user.uid);
      
      const [adminDoc, userDoc] = await Promise.all([
        getDoc(adminDocRef).catch(e => { console.error('Admin UID fetch error:', e); return null; }),
        getDoc(userDocRef).catch(e => { console.error('User UID fetch error:', e); return null; })
      ]);

      if (adminDoc?.exists() || userDoc?.exists()) {
        return { success: true };
      }

      // 2. If UID lookup fails, try searching by email field 
      const adminQuery = query(collection(db, 'admins'), where('email', '==', user.email));
      const userQuery = query(collection(db, 'users'), where('email', '==', user.email));
      
      const [adminSnapshot, userSnapshot] = await Promise.all([
        getDocs(adminQuery).catch(e => { console.error('Admin Email query error:', e); return null; }),
        getDocs(userQuery).catch(e => { console.error('User Email query error:', e); return null; })
      ]);

      const foundByEmail = (adminSnapshot && !adminSnapshot.empty) || (userSnapshot && !userSnapshot.empty);
      
      if (foundByEmail) {
        return { success: true };
      }

      // Still not found
      await signOut(auth);
      return { success: false, message: 'Access denied. You are not registered in our database.' };
    } catch (error: any) {
      console.error('CRITICAL LOGIN ERROR:', error);
      let message = 'An error occurred during login.';
      
      if (error.code && error.code.startsWith('auth/')) {
        switch (error.code) {
          case 'auth/user-not-found':
          case 'auth/wrong-password':
          case 'auth/invalid-credential':
            message = 'Invalid email address or password. Please check your credentials and try again.';
            break;
          case 'auth/invalid-email':
            message = 'The email address provided is not valid. Please enter a correctly formatted email (e.g., name@example.com).';
            break;
          case 'auth/too-many-requests':
            message = 'Access to this account has been temporarily disabled due to many failed login attempts. Please try again later or reset your password.';
            break;
          case 'auth/user-disabled':
            message = 'This account has been disabled. Please contact system support for assistance.';
            break;
          case 'auth/network-request-failed':
            message = 'A network error occurred. Please check your internet connection and try again.';
            break;
          default:
            message = 'Authentication failed. Please verify your details.';
        }
      } else if (error.code === 'permission-denied') {
        message = 'Access denied. You do not have the necessary permissions to access the dashboard.';
      } else {
        message = 'An unexpected error occurred. Please try again or contact support.';
      }
      
      return { success: false, message };
    }
  }

  async logout(): Promise<void> {
    await signOut(auth);
    this.router.navigate(['/login']);
  }

  async resetPassword(email: string): Promise<void> {
    const { sendPasswordResetEmail } = await import('firebase/auth');
    try {
      await sendPasswordResetEmail(auth, email);
    } catch (error: any) {
      console.error('Password reset error:', error);
      throw error;
    }
  }

  isLoggedIn(): boolean {
    return !!this.userSubject.value;
  }

  isInitialized(): boolean {
    return this.authInitialized.value;
  }

  async getAdminDetails(uid: string): Promise<any> {
    try {
      const adminDocRef = doc(db, 'admins', uid);
      const adminDoc = await getDoc(adminDocRef);
      
      if (adminDoc.exists()) {
        return adminDoc.data();
      }
      
      return null;
    } catch (error) {
      console.error('CRITICAL: Failed to fetch admin details:', error);
      return null;
    }
  }
}
