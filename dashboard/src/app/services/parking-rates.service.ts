import { Injectable } from '@angular/core';
import { db } from '../firebase.config';
import { 
  collection, 
  doc, 
  getDoc, 
  getDocs, 
  query, 
  where,
  addDoc,
  serverTimestamp,
  deleteDoc
} from 'firebase/firestore';

export interface ParkingRate {
  id?: string;
  vehicleType: string; 
  type: string;        
  plan: string;
  status: string;
  firstHour: number;
  subsequentHour: number;
  dailyMax: number;
  lostTicket: number;
  effectiveDate?: any;
  adminEmail?: string;
}

@Injectable({
  providedIn: 'root'
})
export class ParkingRatesService {
  private collectionName = 'pricing_rates';

  async getLatestRate(vehicleType: string): Promise<ParkingRate | null> {
    const q = query(
      collection(db, this.collectionName),
      where('vehicleType', '==', vehicleType)
    );
    
    const snapshot = await getDocs(q);
    if (!snapshot.empty) {
      // Sort manually to avoid composite index requirement
      const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as ParkingRate));
      docs.sort((a, b) => {
        const timeA = a.effectiveDate?.toMillis ? a.effectiveDate.toMillis() : 0;
        const timeB = b.effectiveDate?.toMillis ? b.effectiveDate.toMillis() : 0;
        return timeB - timeA;
      });
      return docs[0];
    }
    return null;
  }

  async getRateHistory(vehicleType: string): Promise<ParkingRate[]> {
    const q = query(
      collection(db, this.collectionName),
      where('vehicleType', '==', vehicleType)
    );
    
    const snapshot = await getDocs(q);
    const docs = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as ParkingRate));
    
    // Sort manually to avoid composite index requirement
    docs.sort((a, b) => {
      const timeA = a.effectiveDate?.toMillis ? a.effectiveDate.toMillis() : 0;
      const timeB = b.effectiveDate?.toMillis ? b.effectiveDate.toMillis() : 0;
      return timeB - timeA;
    });
    
    return docs;
  }

  async saveRate(rate: ParkingRate): Promise<void> {
    const data = {
      ...rate,
      effectiveDate: serverTimestamp()
    };
    delete data.id; 
    await addDoc(collection(db, this.collectionName), data);
  }

  async initializeDefaultRates(defaultRates: Record<string, ParkingRate>): Promise<void> {
    for (const [key, rate] of Object.entries(defaultRates)) {
      const existing = await this.getLatestRate(key);
      if (!existing) {
        await this.saveRate({ ...rate, vehicleType: key });
      }
    }
  }

  async cleanupLegacyDocuments(): Promise<void> {
    const legacyIds = ['car', 'bike', 'threeWheeler'];
    for (const id of legacyIds) {
      const docRef = doc(db, this.collectionName, id);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        console.log(`Cleaning up legacy document: ${id}`);
        await deleteDoc(docRef);
      }
    }
  }
}
