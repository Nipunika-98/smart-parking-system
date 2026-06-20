import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { db } from '../firebase.config';
import { doc, onSnapshot, setDoc, Unsubscribe } from 'firebase/firestore';

@Component({
  selector: 'app-system-settings',
  standalone: true,
  imports: [CommonModule, FormsModule, SidebarComponent],
  templateUrl: './system-settings.component.html',
  styleUrl: './system-settings.component.scss'
})
export class SystemSettingsComponent implements OnInit, OnDestroy {
  activeTab = 'general';
  
  private unsubscribeSettings?: Unsubscribe;

  settings = {
    general: {
      systemName: 'SmartPark Kandy',
      timezone: 'Asia/Colombo',
      language: 'English',
      maintenanceMode: false
    },
    notifications: {
      emailAlerts: true,
      smsAlerts: false,
      capacityThreshold: 90,
      dailyReportTime: '18:00'
    },
    security: {
      twoFactorAuth: true,
      sessionTimeout: 30,
      passwordExpiry: 90
    },
    integrations: {
      paymentGateway: 'Stripe',
      apiKey: 'sk_test_123456789',
      iotSyncInterval: 5
    }
  };

  ngOnInit() {
    this.unsubscribeSettings = onSnapshot(doc(db, 'system_config', 'general_settings'), (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        if (data['general']) this.settings.general = data['general'];
        if (data['notifications']) this.settings.notifications = data['notifications'];
        if (data['security']) this.settings.security = data['security'];
        if (data['integrations']) this.settings.integrations = data['integrations'];
      }
    });
  }

  ngOnDestroy() {
    if (this.unsubscribeSettings) {
      this.unsubscribeSettings();
    }
  }

  setTab(tab: string) {
    this.activeTab = tab;
  }

  saveAttempted = false;

  isFormValid(): boolean {
    const s = this.settings;
    if (!s.general.systemName) return false;
    if (s.notifications.capacityThreshold == null || s.notifications.capacityThreshold < 0 || s.notifications.capacityThreshold > 100) return false;
    if (s.security.sessionTimeout == null || s.security.sessionTimeout < 1) return false;
    if (s.security.passwordExpiry == null || s.security.passwordExpiry < 1) return false;
    if (s.integrations.iotSyncInterval == null || s.integrations.iotSyncInterval < 1 || s.integrations.iotSyncInterval > 60) return false;
    return true;
  }

  async saveSettings() {
    this.saveAttempted = true;
    if (this.isFormValid()) {
      try {
        await setDoc(doc(db, 'system_config', 'general_settings'), this.settings, { merge: true });
        alert('Settings saved successfully!');
        this.saveAttempted = false;
      } catch (e) {
        console.error("Error saving config: ", e);
        alert('Failed to save settings. Please try again.');
      }
    }
  }
}

