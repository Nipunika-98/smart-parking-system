import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { UserService, User } from '../services/user.service';
import { db } from '../firebase.config';
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';

@Component({
  selector: 'app-user-directory',
  standalone: true,
  imports: [CommonModule, FormsModule, SidebarComponent],
  templateUrl: './user-directory.component.html',
  styleUrl: './user-directory.component.scss'
})
export class UserDirectoryComponent implements OnInit {
  private userService = inject(UserService);
  
  searchTerm: string = '';
  users: User[] = [];

  async ngOnInit(): Promise<void> {
    await this.loadUsers();
  }

  async loadUsers(): Promise<void> {
    try {
      this.users = await this.userService.getUsers();
    } catch (error) {
      console.error('Failed to load users:', error);
    }
  }

  get filteredUsers(): User[] {
    if (!this.searchTerm) return this.users;
    const term = this.searchTerm.toLowerCase();
    return this.users.filter(u => 
      u.name.toLowerCase().includes(term) ||
      u.id.toLowerCase().includes(term) ||
      u.email.toLowerCase().includes(term) ||
      u.vehicle.toLowerCase().includes(term)
    );
  }

  isEditing = false;
  editingUserId: string | null = null;
  showUserModal = false;
  saveUserAttempted = false;
  newUser: Partial<User> = {
    memberType: 'Standard Member',
    status: 'Active'
  };

  // Notification State
  showNotificationModal = false;
  notificationTarget: User | 'ALL' = 'ALL';
  notificationForm = {
    type: 'Custom',
    title: '',
    message: ''
  };
  notificationSending = false;

  openAddModal() {
    this.isEditing = false;
    this.editingUserId = null;
    this.showUserModal = true;
    this.saveUserAttempted = false;
    this.newUser = { memberType: 'Standard Member', status: 'Active' };
  }

  openEditModal(user: User) {
    this.isEditing = true;
    this.editingUserId = user.id;
    this.showUserModal = true;
    this.saveUserAttempted = false;
    this.newUser = { ...user };
  }

  closeModal() {
    this.showUserModal = false;
    this.saveUserAttempted = false;
  }

  // Notification Methods
  openNotificationModal(user?: User) {
    this.notificationTarget = user || 'ALL';
    this.showNotificationModal = true;
    this.notificationForm = {
      type: 'Custom',
      title: '',
      message: ''
    };
  }

  closeNotificationModal() {
    this.showNotificationModal = false;
  }

  applyTemplate() {
    switch (this.notificationForm.type) {
      case 'Payment Successful':
        this.notificationForm.title = 'Payment Received';
        this.notificationForm.message = 'Thank you! Your parking payment was processed successfully.';
        break;
      case 'Payment Overdue':
        this.notificationForm.title = 'Payment Required';
        this.notificationForm.message = 'You have a pending parking fee. Please complete the payment at the exit gate.';
        break;
      case 'Maintenance Alert':
        this.notificationForm.title = 'Parking Zone Maintenance';
        this.notificationForm.message = 'The parking zone you are currently using is scheduled for maintenance. Please move your vehicle if requested.';
        break;
      case 'Welcome':
        this.notificationForm.title = 'Welcome to SmartPark';
        this.notificationForm.message = 'Welcome! You can now use our digital parking facility seamlessly.';
        break;
      default:
        // Do nothing for 'Custom'
        break;
    }
  }

  async sendNotification() {
    if (!this.notificationForm.title || !this.notificationForm.message) {
      alert('Please provide both a title and message.');
      return;
    }

    this.notificationSending = true;
    try {
      // Determine icon/color based on type for mobile app styling
      let icon = 'notifications';
      let iconColor = '#3b82f6';
      let iconBg = '#eff6ff';

      switch (this.notificationForm.type) {
        case 'Payment Successful':
          icon = 'check_circle';
          iconColor = '#10b981';
          iconBg = '#ecfdf5';
          break;
        case 'Payment Overdue':
          icon = 'warning';
          iconColor = '#ef4444';
          iconBg = '#fef2f2';
          break;
        case 'Maintenance Alert':
          icon = 'build';
          iconColor = '#f59e0b';
          iconBg = '#fffbeb';
          break;
        case 'Welcome':
          icon = 'stars';
          iconColor = '#8b5cf6';
          iconBg = '#f5f3ff';
          break;
      }

      const notificationData = {
        userId: this.notificationTarget === 'ALL' ? 'ALL' : this.notificationTarget.id,
        title: this.notificationForm.title,
        message: this.notificationForm.message,
        type: this.notificationForm.type,
        icon: icon,
        iconColor: iconColor,
        iconBg: iconBg,
        timestamp: serverTimestamp(),
        read: false
      };

      await addDoc(collection(db, 'notifications'), notificationData);
      
      alert('Notification sent successfully!');
      this.closeNotificationModal();
    } catch (error) {
      console.error('Failed to send notification:', error);
      alert('Failed to send notification. Please try again.');
    } finally {
      this.notificationSending = false;
    }
  }

  validateEmail(email: string): boolean {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }

  async saveUser() {
    this.saveUserAttempted = true;
    if (this.newUser.name && this.newUser.email && this.validateEmail(this.newUser.email)) {
      try {
        const userData = {
          name: this.newUser.name,
          memberType: this.newUser.memberType || 'Standard Member',
          email: this.newUser.email,
          phone: this.newUser.phone || '',
          vehicle: this.newUser.vehicle || '',
          status: this.newUser.status || 'Active'
        };

        if (this.isEditing && this.editingUserId) {
          await this.userService.updateUser(this.editingUserId, userData);
        } else {
          await this.userService.addUser(userData);
        }

        await this.loadUsers();
        this.closeModal();
      } catch (error) {
        console.error('Failed to create/update user:', error);
      }
    }
  }

  async deleteUser(userId: string) {
    if(confirm('Are you sure you want to delete this user?')) {
      try {
        await this.userService.deleteUser(userId);
        this.users = this.users.filter(u => u.id !== userId);
      } catch (error) {
        console.error('Failed to delete user:', error);
      }
    }
  }
}
