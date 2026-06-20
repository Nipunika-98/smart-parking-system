import { Component, OnInit, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { ParkingRatesService, ParkingRate } from '../services/parking-rates.service';
import { AuthService } from '../services/auth.service';
import { take } from 'rxjs';

@Component({
  selector: 'app-parking-rates',
  standalone: true,
  imports: [CommonModule, FormsModule, SidebarComponent],
  templateUrl: './parking-rates.component.html',
  styleUrl: './parking-rates.component.scss'
})
export class ParkingRatesComponent implements OnInit {
  private ratesService = inject(ParkingRatesService);
  private authService = inject(AuthService);

  isLoading = true;
  rates: Record<string, ParkingRate> = {
    car: {
      vehicleType: 'car',
      type: 'Car',
      plan: 'Standard Tariff',
      status: 'Not Set',
      firstHour: 0,
      subsequentHour: 0,
      dailyMax: 0,
      lostTicket: 0
    },
    bike: {
      vehicleType: 'bike',
      type: 'Bike',
      plan: 'Standard Tariff',
      status: 'Not Set',
      firstHour: 0,
      subsequentHour: 0,
      dailyMax: 0,
      lostTicket: 0
    },
    threeWheeler: {
      vehicleType: 'threeWheeler',
      type: 'Three-wheeler',
      plan: 'Standard Tariff',
      status: 'Not Set',
      firstHour: 0,
      subsequentHour: 0,
      dailyMax: 0,
      lostTicket: 0
    }
  };

  settings = {
    gracePeriod: 15,
    weekendSurcharge: 0
  };

  isModalOpen = false;
  isHistoryModalOpen = false;
  selectedVehicleKey: string = '';
  editingRate: any = {};
  historyList: ParkingRate[] = [];

  async ngOnInit() {
    await this.loadRates();
  }

  async loadRates() {
    this.isLoading = true;
    try {
      const keys = ['car', 'bike', 'threeWheeler'];
      let foundAny = false;

      for (const key of keys) {
        const latest = await this.ratesService.getLatestRate(key);
        if (latest) {
          this.rates[key] = latest;
          foundAny = true;
        }
      }

      if (!foundAny) {
        console.log('No rates found in DB. Initializing with zeroes...');
        await this.ratesService.initializeDefaultRates(this.rates);
      }
    } catch (error) {
      console.error('Error loading rates:', error);
    } finally {
      this.isLoading = false;
    }
  }

  openEditModal(vehicleKey: string) {
    this.selectedVehicleKey = vehicleKey;
    this.editingRate = { ...this.rates[vehicleKey] };
    this.isModalOpen = true;
  }

  closeModal() {
    this.isModalOpen = false;
    this.isHistoryModalOpen = false;
  }

  async saveRates() {
    try {
      this.isLoading = true;
      this.editingRate.status = 'Active';

      // Get current admin email
      this.authService.user$.pipe(take(1)).subscribe(async (user) => {
        if (user) {
          this.editingRate.adminEmail = user.email || 'unknown';
        }
        await this.ratesService.saveRate(this.editingRate);

        // Refresh the current view
        await this.loadRates();
        this.closeModal();
      });
    } catch (error) {
      console.error('Error saving rates:', error);
      alert('Failed to save rates. Please try again.');
      this.isLoading = false;
    }
  }

  async openHistory(vehicleKey: string) {
    this.selectedVehicleKey = vehicleKey;
    this.isLoading = true;
    try {
      this.historyList = await this.ratesService.getRateHistory(vehicleKey);
      this.isHistoryModalOpen = true;
    } catch (error) {
      console.error('Error fetching history:', error);
    } finally {
      this.isLoading = false;
    }
  }

  formatDate(timestamp: any): string {
    if (!timestamp) return 'Initial Setup';
    // Firestore timestamp to JS Date
    const date = timestamp.toDate ? timestamp.toDate() : new Date(timestamp);
    return date.toLocaleString();
  }
}
