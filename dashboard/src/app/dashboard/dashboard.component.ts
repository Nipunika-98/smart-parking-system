import { Component, OnInit, OnDestroy } from '@angular/core';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { db } from '../firebase.config';
import { collection, onSnapshot, Unsubscribe, query, where } from 'firebase/firestore';
import { ParkingRatesService, ParkingRate } from '../services/parking-rates.service';
import { inject } from '@angular/core';
import { CommonModule } from '@angular/common';

export interface Activity {
  type: string;
  title: string;
  description: string;
  time: string;
  timestampMs: number;
  iconUrl?: string;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, SidebarComponent, BaseChartDirective],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit, OnDestroy {
  private ratesService = inject(ParkingRatesService);
  
  // Statistics data
  availableSlots = { count: 0, label: '0% available' };
  totalParking = { count: 0, label: 'Across 6 zones' };
  activeUsers = { count: 0, label: 'Live' };
  totalRevenue = { amount: 'LKR 0.00', label: 'Loading...' };
  pendingPayments = { count: 0, label: 'Awaiting processing' };

  // Chart Properties
  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        display: false,
      }
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 100,
        title: {
          display: false
        },
        ticks: {
          stepSize: 25,
          callback: function (value) {
            return value + '%';
          }
        },
        grid: {
          color: '#f1f5f9',
          tickColor: 'transparent'
        },
        border: { display: false }
      },
      x: {
        grid: { display: false },
        border: { display: false }
      }
    }
  };
  public barChartType: ChartType = 'bar';
  public barChartData: ChartData<'bar'> = {
    labels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    datasets: [
      {
        data: [65, 72, 85, 90, 95, 82, 55],
        backgroundColor: '#0d7b8a',
        borderRadius: 4,
        barPercentage: 0.6,
        hoverBackgroundColor: '#0b616d'
      }
    ]
  };

  // Recent Activity Data
  activities: Activity[] = [];

  activeTimeFilter: 'Today' | 'Week' | 'Month' = 'Week';

  setTimeFilter(filter: 'Today' | 'Week' | 'Month') {
    this.activeTimeFilter = filter;
    this.calculateRevenueStats();
  }

  private calculateRevenueStats() {
    if (!this.allSessions.length) return;

    const now = new Date();
    let total = 0;
    let pending = 0;

    this.allSessions.forEach(s => {
      if (s.status === 'PENDING') pending++;
      
      const sessionDate = s.entryTime;
      if (!sessionDate) return;

      const isToday = sessionDate.toDateString() === now.toDateString();
      const isThisWeek = (now.getTime() - sessionDate.getTime()) < (7 * 24 * 60 * 60 * 1000);
      const isThisMonth = sessionDate.getMonth() === now.getMonth() && sessionDate.getFullYear() === now.getFullYear();

      // Only count PAID sessions towards "Total Revenue" if marked by an Admin
      if (s.status === 'PAID' && s.rawData['markerByAdmin']) {
        if (this.activeTimeFilter === 'Today' && isToday) total += s.amount;
        if (this.activeTimeFilter === 'Week' && isThisWeek) total += s.amount;
        if (this.activeTimeFilter === 'Month' && isThisMonth) total += s.amount;
      }
    });

    this.totalRevenue.amount = `LKR ${total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    this.totalRevenue.label = `↑ Updated just now`;
    this.pendingPayments.count = pending;
    this.pendingPayments.label = `${pending} sessions active`;

    this.updateCharts(total);
  }

  private updateCharts(total: number) {
    if (this.activeTimeFilter === 'Today') {
      this.barChartData.labels = ['6am', '9am', '12pm', '3pm', '6pm', '9pm'];
      this.barChartData.datasets[0].data = [total * 0.1, total * 0.2, total * 0.3, total * 0.2, total * 0.15, total * 0.05];
    } else if (this.activeTimeFilter === 'Week') {
      this.barChartData.labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      this.barChartData.datasets[0].data = [total * 0.1, total * 0.15, total * 0.2, total * 0.2, total * 0.2, total * 0.1, total * 0.05];
    } else if (this.activeTimeFilter === 'Month') {
      this.barChartData.labels = ['Week 1', 'Week 2', 'Week 3', 'Week 4'];
      this.barChartData.datasets[0].data = [total * 0.2, total * 0.3, total * 0.25, total * 0.25];
    }
    this.barChartData = { ...this.barChartData };
  }

  private unsubscribeParking?: Unsubscribe;
  private unsubscribeUsers?: Unsubscribe;
  private unsubscribeSessions?: Unsubscribe;
  private allSessions: any[] = [];
  private rates: Record<string, ParkingRate> = {};

  ngOnInit() {
    this.setupListeners();
  }

  ngOnDestroy() {
    if (this.unsubscribeParking) this.unsubscribeParking();
    if (this.unsubscribeUsers) this.unsubscribeUsers();
    if (this.unsubscribeSessions) this.unsubscribeSessions();
  }

  async setupListeners() {
    const carRate = await this.ratesService.getLatestRate('car');
    const bikeRate = await this.ratesService.getLatestRate('bike');
    const threeWheelerRate = await this.ratesService.getLatestRate('threeWheeler');
    if (carRate) this.rates['car'] = carRate;
    if (bikeRate) this.rates['bike'] = bikeRate;
    if (threeWheelerRate) this.rates['threeWheeler'] = threeWheelerRate;

    this.unsubscribeParking = onSnapshot(collection(db, 'parking_slots'), (snap) => {
      let total = 0;
      let available = 0;
      snap.docs.forEach(doc => {
        total++;
        if (doc.data()['status'] === 'AVAILABLE') {
          available++;
        }
      });
      this.totalParking.count = total;
      this.availableSlots.count = available;
      let percent = total > 0 ? Math.round((available / total) * 100) : 0;
      this.availableSlots.label = `${percent}% available`;
    });

    this.unsubscribeUsers = onSnapshot(collection(db, 'users'), (snap) => {
      this.activeUsers.count = snap.size;
    });

    this.unsubscribeSessions = onSnapshot(collection(db, 'parking_sessions'), (snap) => {
      this.allSessions = snap.docs.map(doc => {
        const data = doc.data();
        const entryTime = data['entryTime']?.toDate ? data['entryTime'].toDate() : null;
        const exitTime = data['exitTime']?.toDate ? data['exitTime'].toDate() : null;
        const status = data['paymentStatus'] || 'PENDING';
        
        let amount = data['amount'] || data['totalAmount'] || 0;
        
        if (amount === 0 && entryTime) {
          const end = exitTime || new Date();
          const durationHrs = Math.ceil((end.getTime() - entryTime.getTime()) / 3600000);
          
          const rate = this.rates['car'] || { firstHour: 100, subsequentHour: 100 };
          amount = rate.firstHour + (Math.max(0, durationHrs - 1) * rate.subsequentHour);
        }

        const ticketNumber = data['ticketNumber'] || 'N/A';
        const userId = data['userId'] || 'Unknown User';

        return { entryTime, exitTime, status, amount, ticketNumber, userId, rawData: data };
      });
      this.calculateRevenueStats();
      this.updateActivities();
    });
  }

  private updateActivities() {
    const events: Activity[] = [];
    const now = new Date();

    this.allSessions.forEach(s => {
      if (s.entryTime) {
        const diffMins = Math.floor((now.getTime() - s.entryTime.getTime()) / 60000);
        events.push({
          type: s.status,
          title: s.ticketNumber,
          description: `Status: ${s.status} • User: ${s.userId.substring(0,6)}`,
          time: this.formatTimeDiff(diffMins),
          timestampMs: s.entryTime.getTime()
        });
      }

      if (s.status === 'PAID' && s.exitTime) {
        const diffMins = Math.floor((now.getTime() - s.exitTime.getTime()) / 60000);
        events.push({
          type: s.status,
          title: s.ticketNumber,
          description: `Status: ${s.status} • Paid LKR ${s.amount.toFixed(2)}`,
          time: this.formatTimeDiff(diffMins),
          timestampMs: s.exitTime.getTime()
        });
      }
    });

    events.sort((a, b) => b.timestampMs - a.timestampMs);
    this.activities = events.slice(0, 5);
  }

  private formatTimeDiff(mins: number): string {
    if (mins < 1) return 'Just now';
    if (mins < 60) return `${mins} mins ago`;
    const hrs = Math.floor(mins / 60);
    if (hrs < 24) return `${hrs} hours ago`;
    return `${Math.floor(hrs / 24)} days ago`;
  }
}
