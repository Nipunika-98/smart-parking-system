import { Component, OnInit, OnDestroy } from '@angular/core';
import { CommonModule } from '@angular/common';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { db } from '../firebase.config';
import { collection, onSnapshot, doc, updateDoc, Unsubscribe } from 'firebase/firestore';

@Component({
  selector: 'app-parking-slot-management',
  standalone: true,
  imports: [CommonModule, SidebarComponent],
  templateUrl: './parking-slot-management.component.html',
  styleUrl: './parking-slot-management.component.scss'
})
export class ParkingSlotManagementComponent implements OnInit, OnDestroy {
  private unsubscribeSlots?: Unsubscribe;

  selectedLevel = 'Level 1';
  selectedFilter = 'All';

  levels = ['Level 1', 'Level 2', 'Level 3', 'All'];
  filters = ['All', 'Cars', 'Bikes', '3-Wheel'];

  filledCount = 0;
  emptyCount = 0;
  
  allZones: any[] = [];

  async ngOnInit() {
    this.setupRealtimeListener();
  }

  ngOnDestroy() {
    if (this.unsubscribeSlots) {
      this.unsubscribeSlots();
    }
  }

  setupRealtimeListener() {
    try {
      this.unsubscribeSlots = onSnapshot(collection(db, 'parking_slots'), (snap) => {
        const slots = snap.docs.map(doc => ({ ...(doc.data() as any), docId: doc.id }));
        
        const grouped: { [key: string]: any[] } = {
          'A': [], 'B': [], 'C': [], 'D': [], 'E': [], 'F': []
        };
        
        slots.forEach(s => {
          const slotNumber = s['slotNumber'] as string;
          if (slotNumber) {
            const section = slotNumber.split('-')[0];
            const numericPart = parseInt(slotNumber.split('-')[1], 10);
            
            let type = 'car';
            if (numericPart > 5) {
              type = ['A', 'C', 'E'].includes(section) ? '3wheel' : 'bike';
            }

            let state = 'empty';
            const dbStatus = s['status'];
            if (dbStatus === 'AVAILABLE') {
              state = type === 'car' ? 'empty' : `empty-${type === '3wheel' ? '3wheel' : 'bikes'}`;
            } else if (dbStatus === 'MAINTENANCE') {
              state = 'maintenance';
            } else {
              state = type === 'car' ? 'filled-dark' : `filled-${type === '3wheel' ? '3wheel' : 'bikes'}`;
            }
            if (grouped[section]) {
              grouped[section].push({ 
                id: slotNumber, 
                displayId: slotNumber.replace('-', ''), 
                type, 
                state,
                docId: s['docId'],
                rawStatus: dbStatus
              });
            }
          }
        });
        
        this.allZones = Object.keys(grouped).map(section => {
          const sectionSlots = grouped[section].sort((a,b) => a.id.localeCompare(b.id));
          return {
            id: section,
            name: `Zone ${section}`,
            level: section === 'A' || section === 'B' ? 'Level 1' : 
                   section === 'C' || section === 'D' ? 'Level 2' : 'Level 3',
            left: sectionSlots.slice(0, 5),
            right: sectionSlots.slice(5, 10)
          };
        });
        
        this.updateCounts();
      }, (error) => {
        console.error("Error listening to slots:", error);
      });
    } catch (e) {
      console.error("Error setting up listener", e);
    }
  }

  get displayedZones() {
    if (this.selectedLevel === 'All') return this.allZones;
    return this.allZones.filter(z => z.level === this.selectedLevel);
  }

  selectLevel(level: string) {
    this.selectedLevel = level;
    this.updateCounts();
  }
  
  updateCounts() {
    let empty = 0;
    let filled = 0;
    this.displayedZones.forEach(z => {
      z.left.forEach((s: any) => s.state.includes('empty') ? empty++ : filled++);
      z.right.forEach((s: any) => s.state.includes('empty') ? empty++ : filled++);
    });
    this.emptyCount = empty;
    this.filledCount = filled;
  }

  async toggleSlotStatus(slot: any) {
    if (!slot || !slot.docId) return;

    let nextStatus = 'AVAILABLE';
    if (slot.rawStatus === 'AVAILABLE') nextStatus = 'OCCUPIED';
    else if (slot.rawStatus === 'OCCUPIED') nextStatus = 'MAINTENANCE';
    else nextStatus = 'AVAILABLE'; 

    try {
      const docRef = doc(db, 'parking_slots', slot.docId);
      await updateDoc(docRef, { status: nextStatus, lastUpdated: new Date() });
    } catch (err) {
      console.error("Failed to update slot status:", err);
      alert('Error updating slot status. Make sure you have sufficient permissions.');
    }
  }

  reportProblem() {
    alert("Report Problem Modal will be launched here. (Support Ticket system integration)");
  }

  selectFilter(filter: any) {
    this.selectedFilter = filter;
  }

  isSlotVisible(slot: any): boolean {
    if (this.selectedFilter === 'All') return true;
    if (this.selectedFilter === 'Cars' && slot.type === 'car') return true;
    if (this.selectedFilter === 'Bikes' && slot.type === 'bike') return true;
    if (this.selectedFilter === '3-Wheel' && slot.type === '3wheel') return true;
    return false;
  }
}

