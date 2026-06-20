import { Component, inject } from '@angular/core';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../services/auth.service';
import { filter, take } from 'rxjs';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrl: './login.component.scss'
})
export class LoginComponent {
  passwordVisible = false;
  email = '';
  password = '';
  emailError = '';
  passwordError = '';
  loginError = '';
  isLoading = false;

  private router = inject(Router);
  private authService = inject(AuthService);


  togglePasswordVisibility(): void {
    this.passwordVisible = !this.passwordVisible;
  }

  validateEmail(email: string): boolean {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }

  async onLogin(event: Event): Promise<void> {
    event.preventDefault();
    this.emailError = '';
    this.passwordError = '';
    this.loginError = '';

    let isValid = true;

    if (!this.email) {
      this.emailError = 'Please provide your email address to log in.';
      isValid = false;
    } else if (!this.validateEmail(this.email)) {
      this.emailError = 'The email address you entered doesn\'t look right. Please check for typos.';
      isValid = false;
    }

    if (!this.password) {
      this.passwordError = 'Your password is required to continue.';
      isValid = false;
    }

    if (isValid) {
      this.isLoading = true;
      try {
        const result = await this.authService.login(this.email, this.password);
        if (result.success) {
          this.router.navigate(['/dashboard']);
        } else {
          this.loginError = result.message || 'Login failed. Please try again.';
        }
      } catch (error) {
        this.loginError = 'An unexpected error occurred. Please try again.';
      } finally {
        this.isLoading = false;
      }
    }
  }

  async forgotPassword(event: Event): Promise<void> {
    event.preventDefault();
    this.emailError = '';
    this.loginError = '';

    if (!this.email) {
      this.emailError = 'Please enter your email address to receive a reset link.';
      return;
    }

    if (!this.validateEmail(this.email)) {
      this.emailError = 'The email address format is incorrect. Please double-check it.';
      return;
    }

    try {
      await this.authService.resetPassword(this.email);
      alert('Success! A password reset link has been sent to your inbox. Please check your email.');
    } catch (error: any) {
      if (error.code === 'auth/user-not-found') {
        this.loginError = 'We couldn\'t find an account associated with this email address.';
      } else {
        this.loginError = 'We encountered an error sending the reset email. Please try again in a few moments.';
      }
    }
  }
}
