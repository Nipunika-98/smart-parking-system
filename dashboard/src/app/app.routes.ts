import { Routes } from '@angular/router';
import { LoginComponent } from './login/login.component';
import { DashboardComponent } from './dashboard/dashboard.component';
import { ParkingRatesComponent } from './parking-rates/parking-rates.component';
import { TransactionLogsComponent } from './transaction-logs/transaction-logs.component';
import { ReportsComponent } from './reports/reports.component';
import { ParkingSlotManagementComponent } from './parking-slot-management/parking-slot-management.component';
import { UserDirectoryComponent } from './user-directory/user-directory.component';
import { SystemSettingsComponent } from './system-settings/system-settings.component';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { path: 'dashboard', component: DashboardComponent, canActivate: [authGuard] },
  { path: 'parking-rates', component: ParkingRatesComponent, canActivate: [authGuard] },
  { path: 'transaction-logs', component: TransactionLogsComponent, canActivate: [authGuard] },
  { path: 'reports', component: ReportsComponent, canActivate: [authGuard] },
  { path: 'parking-slot-management', component: ParkingSlotManagementComponent, canActivate: [authGuard] },
  { path: 'user-directory', component: UserDirectoryComponent, canActivate: [authGuard] },
  { path: 'system-settings', component: SystemSettingsComponent, canActivate: [authGuard] },
  { path: '**', redirectTo: 'login' }
];
