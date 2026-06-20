import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { BaseChartDirective } from 'ng2-charts';
import { ChartConfiguration, ChartData, ChartType } from 'chart.js';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { db } from '../firebase.config';
import { collection, onSnapshot, Unsubscribe, addDoc } from 'firebase/firestore';
import { ParkingRatesService, ParkingRate } from '../services/parking-rates.service';
import { inject, OnInit, OnDestroy } from '@angular/core';
import { FormsModule } from '@angular/forms';

@Component({
  selector: 'app-reports',
  standalone: true,
  imports: [CommonModule, BaseChartDirective, SidebarComponent, FormsModule],
  templateUrl: './reports.component.html',
  styleUrl: './reports.component.scss'
})
export class ReportsComponent implements OnInit, OnDestroy {
  private ratesService = inject(ParkingRatesService);

  // Statistics Display
  stats = {
    totalRevenue: 0,
    transactionCount: 0,
    avgTransaction: 0,
    dailyAverage: 0
  };

  userStats = {
    totalUsers: 0,
    newToday: 0,
    activeUsers: 0,
    bannedUsers: 0
  };

  activeTab: 'Revenue' | 'Users' = 'Revenue';

  // Filters
  startDate: string = '';
  endDate: string = '';

  private allSessions: any[] = [];
  private allUsers: any[] = [];
  private rates: Record<string, ParkingRate> = {};
  private unsubscribeSessions?: Unsubscribe;
  private unsubscribeUsers?: Unsubscribe;
  // Chart Properties for Revenue Overview
  public barChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        max: 60000,
        ticks: {
          stepSize: 15000,
          callback: function (value) { return 'LKR ' + value; }
        },
        grid: { color: '#f1f5f9', tickColor: 'transparent' },
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
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: '#0d7b8a',
      borderRadius: 4,
      barPercentage: 0.6,
      hoverBackgroundColor: '#0b616d'
    }]
  };

  public userChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { display: false }
    },
    scales: {
      y: {
        beginAtZero: true,
        ticks: { stepSize: 1 },
        grid: { color: '#f1f5f9', tickColor: 'transparent' },
        border: { display: false }
      },
      x: {
        grid: { display: false },
        border: { display: false }
      }
    }
  };

  public userChartType: ChartType = 'bar';
  public userChartData: ChartData<'bar'> = {
    labels: [],
    datasets: [{
      data: [],
      backgroundColor: '#f59e0b',
      borderRadius: 4,
      barPercentage: 0.6,
      hoverBackgroundColor: '#d97706',
      label: 'New Registrations'
    }]
  };

  ngOnInit() {
    // Default to last 7 days
    const end = new Date();
    const start = new Date();
    start.setDate(end.getDate() - 7);
    this.startDate = start.toISOString().split('T')[0];
    this.endDate = end.toISOString().split('T')[0];

    this.setupData();
  }

  ngOnDestroy() {
    if (this.unsubscribeSessions) this.unsubscribeSessions();
    if (this.unsubscribeUsers) this.unsubscribeUsers();
  }

  async setupData() {
    // Fetch rates
    const carRate = await this.ratesService.getLatestRate('car');
    const bikeRate = await this.ratesService.getLatestRate('bike');
    const threeWheelerRate = await this.ratesService.getLatestRate('threeWheeler');
    if (carRate) this.rates['car'] = carRate;
    if (bikeRate) this.rates['bike'] = bikeRate;
    if (threeWheelerRate) this.rates['threeWheeler'] = threeWheelerRate;

    this.unsubscribeSessions = onSnapshot(collection(db, 'parking_sessions'), (snap) => {
      this.allSessions = snap.docs.map(doc => {
        const data = doc.data();
        const entryTime = data['entryTime']?.toDate ? data['entryTime'].toDate() : null;
        const exitTime = data['exitTime']?.toDate ? data['exitTime'].toDate() : null;
        const status = data['paymentStatus'] || 'PENDING';
        const ticketNumber = data['ticketNumber'] || 'N/A';
        const userId = data['userId'] || 'Unknown';

        let amount = 0;
        if (entryTime) {
          const end = exitTime || new Date();
          const durationHrs = Math.ceil((end.getTime() - entryTime.getTime()) / 3600000);
          const rate = this.rates['car'] || { firstHour: 100, subsequentHour: 100 };
          amount = rate.firstHour + (Math.max(0, durationHrs - 1) * rate.subsequentHour);
        }

        return { entryTime, exitTime, status, amount, ticketNumber, userId };
      });
      this.updateStats();
    });

    this.unsubscribeUsers = onSnapshot(collection(db, 'users'), (snap) => {
      this.allUsers = snap.docs.map(doc => {
        const data = doc.data();
        const regDate = data['registrationDate'] || data['createdAt'] || data['joinedAt'];
        return {
          id: doc.id,
          name: data['name'] || 'Unknown',
          email: data['email'] || '',
          status: data['status'] || 'Active',
          createdAt: regDate?.toDate ? regDate.toDate() : (regDate instanceof Date ? regDate : null)
        };
      });
      this.updateUserStats();
    });
  }

  updateUserStats() {
    const start = this.startDate ? new Date(this.startDate) : new Date(0);
    const end = this.endDate ? new Date(this.endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    const now = new Date();
    let newToday = 0;
    this.allUsers.forEach(u => {
      if (u.createdAt && u.createdAt.toDateString() === now.toDateString()) {
        newToday++;
      }
    });

    // Calculate Global Counts 
    this.userStats.totalUsers = this.allUsers.length;
    this.userStats.activeUsers = this.allUsers.filter(u => u.status === 'Active').length;
    this.userStats.bannedUsers = this.allUsers.filter(u => u.status === 'Banned').length;
    this.userStats.newToday = newToday;

    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const currentYear = new Date().getFullYear();
    const monthlyData: number[] = new Array(12).fill(0);

    this.allUsers.forEach(u => {
      const date = u.createdAt || new Date();
      if (date.getFullYear() === currentYear) {
        monthlyData[date.getMonth()] += 1;
      }
    });

    this.userChartData.labels = months;
    this.userChartData.datasets[0].data = monthlyData;
    this.userChartData = { ...this.userChartData };
  }

  updateStats() {
    const start = this.startDate ? new Date(this.startDate) : new Date(0);
    const end = this.endDate ? new Date(this.endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    const filtered = this.allSessions.filter(s => {
      if (!s.entryTime) return false;
      return s.entryTime >= start && s.entryTime <= end;
    });

    const totalRevenue = filtered.filter(s => s.status === 'PAID').reduce((acc, s) => acc + s.amount, 0);
    const transactionCount = filtered.length;

    this.stats.totalRevenue = totalRevenue;
    this.stats.transactionCount = transactionCount;
    this.stats.avgTransaction = transactionCount > 0 ? totalRevenue / transactionCount : 0;

    const days = Math.max(1, Math.ceil((end.getTime() - start.getTime()) / (1000 * 60 * 60 * 24)));
    this.stats.dailyAverage = totalRevenue / days;

    // Update Chart
    const dailyData: Record<string, number> = {};
    filtered.forEach(s => {
      if (s.status === 'PAID') {
        const dateStr = s.entryTime.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
        dailyData[dateStr] = (dailyData[dateStr] || 0) + s.amount;
      }
    });

    this.barChartData.labels = Object.keys(dailyData);
    this.barChartData.datasets[0].data = Object.values(dailyData);
    this.barChartData = { ...this.barChartData };
    this.updateUserStats();
  }

  exportReport() {
    if (this.activeTab === 'Revenue') {
      this.exportRevenueReport();
    } else {
      this.exportUserReport();
    }
  }

  private async exportRevenueReport() {
    const start = this.startDate ? new Date(this.startDate) : new Date(0);
    const end = this.endDate ? new Date(this.endDate) : new Date();
    const filtered = this.allSessions.filter(s => s.entryTime >= start && s.entryTime <= end);

    let csvContent = "data:text/csv;charset=utf-8,";
    csvContent += "Ticket Number,User ID,Entry Time,Exit Time,Status,Amount (LKR)\n";

    filtered.forEach(s => {
      const row = [
        s.ticketNumber,
        s.userId,
        s.entryTime?.toLocaleString() || 'N/A',
        s.exitTime?.toLocaleString() || 'N/A',
        s.status,
        s.amount
      ].join(",");
      csvContent += row + "\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `Parking_Revenue_${this.startDate}_to_${this.endDate}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Log the revenue report generation to Firestore
    try {
      const { auth } = await import('../firebase.config');
      const totalRevenue = filtered.filter(s => s.status === 'PAID').reduce((acc, s) => acc + s.amount, 0);

      await addDoc(collection(db, 'reports'), {
        adminId: auth.currentUser?.uid || 'SYSTEM',
        dateFrom: start,
        dateTo: end,
        generatedTime: new Date(),
        reportData: JSON.stringify({ totalRevenue: totalRevenue, sessions: filtered.length }),
        reportPeriod: 'CUSTOM',
        reportType: 'REVENUE_REPORT'
      });
    } catch (error) {
      console.error('Error logging report generation:', error);
    }
  }

  private async exportUserReport() {
    const start = this.startDate ? new Date(this.startDate) : new Date(0);
    const end = this.endDate ? new Date(this.endDate) : new Date();
    end.setHours(23, 59, 59, 999);

    const filtered = this.allUsers.filter(u => {
      if (!u.createdAt) return true;
      return u.createdAt >= start && u.createdAt <= end;
    });

    let csvContent = "data:text/csv;charset=utf-8,";
    csvContent += "User ID,Name,Email,Status,Registration Date\n";

    filtered.forEach(u => {
      const row = [
        u.id,
        u.name,
        u.email,
        u.status,
        u.createdAt?.toLocaleString() || 'Unknown'
      ].join(",");
      csvContent += row + "\n";
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `User_Statistics_${this.startDate}_to_${this.endDate}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    // Log the user statistics report generation to Firestore
    try {
      const { auth } = await import('../firebase.config');
      await addDoc(collection(db, 'reports'), {
        adminId: auth.currentUser?.uid || 'SYSTEM',
        dateFrom: start,
        dateTo: end,
        generatedTime: new Date(),
        reportData: JSON.stringify({ totalUsers: this.allUsers.length, newUsers: filtered.length }),
        reportPeriod: 'CUSTOM',
        reportType: 'USER_STATISTICS'
      });
    } catch (error) {
      console.error('Error logging report generation:', error);
    }
  }
}
