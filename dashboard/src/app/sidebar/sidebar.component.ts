import { Component, inject, OnInit } from '@angular/core';
import { RouterModule, Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [RouterModule, CommonModule],
  templateUrl: './sidebar.component.html',
  styleUrl: './sidebar.component.scss'
})
export class SidebarComponent implements OnInit {
  private router = inject(Router);
  private authService = inject(AuthService);

  userEmail: string | null = null;
  userName: string = 'Admin User';
  userInitial: string = 'AD';

  ngOnInit() {
    this.authService.user$.subscribe(user => {
      if (user) {
        this.userEmail = user.email;
        this.fetchAdminDetails(user.uid);
      }
    });
  }

  async fetchAdminDetails(uid: string) {
    try {
      const details = await this.authService.getAdminDetails(uid);

      // 1. Prioritize Firestore fields
      let name = details?.['adminName'] || details?.['name'] || details?.['displayName'] || details?.['username'];

      if (name) {
        this.userName = name;
        console.log(`Admin name found in Firestore: ${name}`);
      } else if (this.userEmail) {
        // Fallback: use part of email as name
        this.userName = this.userEmail.split('@')[0];
        console.log(`No name in Firestore. Attempting self-healing for: ${this.userName}`);

        // SELF-HEALING: If we have a document but no name, or no document, try to create/fix it
        await this.repairProfile(uid, this.userName, this.userEmail);
      }

      // 2. Multi-part Initial Generation (e.g. "NB")
      this.generateInitials();
    } catch (error) {
      console.error('Error fetching admin details for sidebar:', error);
    }
  }

  async repairProfile(uid: string, name: string, email: string) {
    try {
      // Basic repair logic: Save the name to the UID-based document in 'admins'
      const { doc, setDoc } = await import('firebase/firestore');
      const { db } = await import('../firebase.config');

      console.log(`Repairing profile for UID: ${uid}...`);
      await setDoc(doc(db, 'admins', uid), {
        adminName: name,
        email: email,
        role: 'Admin',
        registrationDate: new Date()
      }, { merge: true });

      console.log('Profile repaired successfully!');
    } catch (e) {
      console.warn('Could not auto-repair profile:', e);
    }
  }

  generateInitials() {
    if (this.userName) {
      const parts = this.userName.trim().split(/\s+/);
      if (parts.length >= 2) {
        this.userInitial = (parts[0][0] + parts[1][0]).toUpperCase();
      } else {
        this.userInitial = this.userName.substring(0, 2).toUpperCase();
      }
    }
  }

  async signOut(event: Event) {
    event.preventDefault();
    await this.authService.logout();
  }
}
