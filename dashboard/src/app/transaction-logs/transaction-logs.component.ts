import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { db } from '../firebase.config';
import { collection, onSnapshot, doc, updateDoc, serverTimestamp, setDoc, addDoc } from 'firebase/firestore';
import { ParkingRatesService, ParkingRate } from '../services/parking-rates.service';
import { AuthService } from '../services/auth.service';
import { inject } from '@angular/core';

interface Transaction {
  id: string; 
  ticketNumber: string;
  userName: string;
  dateTime: string;
  duration: string;
  amount: number;
  paymentMethod: string;
  status: string; // 'PAID' or 'PENDING'
  vehicleType: string;
  rawEntryDate: Date | null;
  rawExitDate: Date | null;
  fullUserId: string;
  isReadyForPayment: boolean;
}

@Component({
  selector: 'app-transaction-logs',
  imports: [CommonModule, FormsModule, SidebarComponent],
  templateUrl: './transaction-logs.component.html',
  styleUrl: './transaction-logs.component.scss'
})
export class TransactionLogsComponent implements OnInit, OnDestroy {
  private ratesService = inject(ParkingRatesService);
  private authService = inject(AuthService);
  private rates: Record<string, ParkingRate> = {};
  
  currentAdminName: string = 'Admin';
  selectedDate: string = '';
  selectedStatus: string = 'All Statuses';
  searchQuery: string = '';

  transactions: Transaction[] = [];
  unsubscribeSessions: any;

  // QR Modal logic
  showQrModal = false;
  entryQrUrl = '';
  exitQrUrl = '';

  async ngOnInit() {
    // Fetch latest rates for accurate calculations
    const carRate = await this.ratesService.getLatestRate('car');
    const bikeRate = await this.ratesService.getLatestRate('bike');
    const threeWheelerRate = await this.ratesService.getLatestRate('threeWheeler');
    if (carRate) this.rates['car'] = carRate;
    if (bikeRate) this.rates['bike'] = bikeRate;
    if (threeWheelerRate) this.rates['threeWheeler'] = threeWheelerRate;

    // Fetch current admin name for marking records
    this.authService.user$.subscribe(async (user) => {
      if (user) {
        const details = await this.authService.getAdminDetails(user.uid);
        this.currentAdminName = details?.['adminName'] || details?.['name'] || user.displayName || user.email?.split('@')[0] || 'Admin';
      }
    });

    this.unsubscribeSessions = onSnapshot(collection(db, 'parking_sessions'), (snap) => {
      this.transactions = snap.docs.map(docSnap => {
        const data = docSnap.data();
        
        let entryDate: Date | null = null;
        let exitDate: Date | null = null;
        if (data['entryTime']) entryDate = data['entryTime'].toDate ? data['entryTime'].toDate() : new Date(data['entryTime']);
        if (data['exitTime']) exitDate = data['exitTime'].toDate ? data['exitTime'].toDate() : new Date(data['exitTime']);

        let duration = '-';
        if (entryDate) {
          const end = exitDate || new Date();
          const diffMs = end.getTime() - entryDate.getTime();
          const mins = Math.floor(diffMs / 60000);
          duration = `${Math.floor(mins / 60)}h ${mins % 60}m`;
        }

        // Use actual amount from DB (stored on exit) or calculate dynamically as fallback
        let amt = data['amount'] || data['totalAmount'] || 0;
        
        if (amt === 0 && entryDate) {
          const end = exitDate || new Date();
          const diffMs = end.getTime() - entryDate.getTime();
          const hours = Math.ceil(diffMs / 3600000);
          
          // Use vehicle-specific rates
          const vType = (data['vehicleType'] || 'car').toLowerCase();
          const rate = this.rates[vType] || this.rates['car'] || { firstHour: 100, subsequentHour: 100 };
          amt = rate.firstHour + (Math.max(0, hours - 1) * rate.subsequentHour);
        }

        // Manual Payment Recognition Logic:
        // Strictly use the database paymentStatus AND check for manual admin confirmation.
        // This prevents automatic mobile/IoT updates from hiding the Admin action button.
        const isAdminConfirmed = !!(data['paymentStatus'] === 'PAID' && data['markerByAdmin']);
        const finalStatus = isAdminConfirmed ? 'PAID' : 'PENDING';

        // READY State: If exitTime exists but Admin hasn't marked as PAID yet
        const isReadyForPayment = !!(exitDate && !isAdminConfirmed);

        return {
          id: docSnap.id,
          ticketNumber: data['ticketNumber'] || 'N/A',
          userName: data['userId'] ? data['userId'].substring(0,8) + '...' : 'Unknown User',
          dateTime: entryDate ? entryDate.toLocaleString() : 'N/A',
          duration: duration,
          amount: amt,
          paymentMethod: 'Manual/Cash',
          status: finalStatus,
          vehicleType: data['vehicleType'] || 'Car',
          rawEntryDate: entryDate,
          rawExitDate: exitDate,
          fullUserId: data['userId'] || '',
          isReadyForPayment: isReadyForPayment
        };
      });
    });
  }

  ngOnDestroy() {
    if (this.unsubscribeSessions) this.unsubscribeSessions();
  }

  async markPaid(txn: Transaction) {
    if (txn.status === 'PAID') return;
    try {
      const docRef = doc(db, 'parking_sessions', txn.id);
      await updateDoc(docRef, {
        paymentStatus: 'PAID',
        paymentTime: serverTimestamp(),
        markerByAdmin: this.currentAdminName,
        amount: txn.amount,
        finalAmount: txn.amount
      });

      // Automatically send "Payment Successful" notification
      if (txn.fullUserId) {
        await addDoc(collection(db, 'notifications'), {
          userId: txn.fullUserId,
          title: 'Payment Successful',
          message: `Your payment for ticket ${txn.ticketNumber} was successful. Thank you!`,
          type: 'Payment Successful',
          icon: 'check_circle',
          iconColor: '#10b981',
          iconBg: '#ecfdf5',
          timestamp: serverTimestamp(),
          read: false
        });
      }

      alert('Payment marked as paid and notification sent.');
    } catch (e) {
      console.error("Failed to mark paid", e);
      alert('Error updating payment status.');
    }
  }

  generateWeeklyQRs() {
    const weekTimestamp = new Date().toISOString().split('T')[0]; // simple week key
    const entryToken = `ENTRY_GATE_${weekTimestamp}`;
    const exitToken = `EXIT_GATE_${weekTimestamp}`;
    
    // Using a reliable public API to encode the raw string token so the UI can physically view it.
    this.entryQrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${entryToken}`;
    this.exitQrUrl = `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${exitToken}`;
    
    this.showQrModal = true;

    // save these tokens to a `qr_config` document so the IoT scanners know the week's valid code!
    setDoc(doc(db, 'system_config', 'current_gate_qrs'), {
      entryToken: entryToken,
      exitToken: exitToken,
      generatedOn: serverTimestamp()
    });
  }

  closeQrModal() {
    this.showQrModal = false;
  }

  downloadQR(url: string, filename: string) {
    fetch(url)
      .then(response => response.blob())
      .then(blob => {
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
      })
      .catch(err => {
        console.error("Download failed:", err);
        window.open(url, '_blank');
      });
  }

  get filteredTransactions() {
    const list = this.transactions.filter(txn => {
      const matchStatus = this.selectedStatus === 'All Statuses' || txn.status === this.selectedStatus;
      
      let matchDate = true;
      if (this.selectedDate && txn.rawEntryDate) {
        // Date input yields YYYY-MM-DD which parses effectively
        const selDate = new Date(this.selectedDate);
        if (!isNaN(selDate.getTime())) {
          matchDate = selDate.toDateString() === txn.rawEntryDate.toDateString();
        }
      }

      let matchSearch = true;
      if (this.searchQuery && this.searchQuery.trim() !== '') {
        const term = this.searchQuery.toLowerCase().trim();
        matchSearch = txn.ticketNumber.toLowerCase().includes(term) || txn.userName.toLowerCase().includes(term);
      }

      return matchStatus && matchDate && matchSearch;
    });

    // Intelligent Sorting:
    // 1. PIN "READY" sessions to the top
    // 2. Sort READY sessions by most recent exit time
    // 3. Sort Others by most recent entry time
    return list.sort((a, b) => {
      if (a.isReadyForPayment && !b.isReadyForPayment) return -1;
      if (!a.isReadyForPayment && b.isReadyForPayment) return 1;

      if (a.isReadyForPayment && b.isReadyForPayment) {
        const timeA = a.rawExitDate?.getTime() || 0;
        const timeB = b.rawExitDate?.getTime() || 0;
        return timeB - timeA;
      }

      const entryA = a.rawEntryDate?.getTime() || 0;
      const entryB = b.rawEntryDate?.getTime() || 0;
      return entryB - entryA;
    });
  }

  resetFilters() {
    this.selectedDate = '';
    this.selectedStatus = 'All Statuses';
    this.searchQuery = '';
  }
}

