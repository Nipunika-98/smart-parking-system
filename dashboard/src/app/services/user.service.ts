import { Injectable } from '@angular/core';
import { db } from '../firebase.config';
import {
  collection,
  getDocs,
  addDoc,
  deleteDoc,
  doc,
  updateDoc,
  query,
  where,
  limit,
  serverTimestamp
} from 'firebase/firestore';

export interface User {
  id: string;
  name: string;
  email: string;
  phone: string;
  vehicle: string;
  memberType: string;
  status: string;
  [key: string]: any;
}

@Injectable({
  providedIn: 'root'
})
export class UserService {
  private collectionName = 'users';

  async getUsers(): Promise<User[]> {
    const querySnapshot = await getDocs(collection(db, this.collectionName));

    // Fetch users first
    const usersData = querySnapshot.docs.map(docSnapshot => {
      const data = docSnapshot.data() as any;
      return { id: docSnapshot.id, ...data };
    });

    // Resolve all primary vehicles concurrently
    const usersWithVehicles = await Promise.all(usersData.map(async (data: any) => {
      let mappedVehicle = data['vehicle'] || data['licensePlate'] || data['primaryVehicle'] || 'N/A';

      // Attempt to find primary vehicle in the vehicles collection
      try {
        const vQuery = query(
          collection(db, 'vehicles'),
          where('userId', '==', data.id),
          where('isPrimary', '==', true),
          limit(1)
        );
        const vSnapshot = await getDocs(vQuery);
        if (!vSnapshot.empty) {
          mappedVehicle = vSnapshot.docs[0].data()['vehiclePlateNo'] || mappedVehicle;
        }
      } catch (error) {
        console.error(`Failed to fetch vehicle for user ${data.id}`, error);
      }

      const mappedName = data['name'] || data['fullName'] || data['displayName'] ||
        ((data['firstName'] || '') + ' ' + (data['lastName'] || '')).trim() || 'Unknown User';

      const mappedPhone = data['phone'] || data['phoneNumber'] || 'N/A';
      const mappedStatus = data['status'] || 'Active';
      const mappedMemberType = data['memberType'] || data['role'] || 'Standard Member';
      const email = data['email'] || 'N/A';

      return {
        ...data,
        id: data.id,
        name: mappedName,
        email,
        phone: mappedPhone,
        vehicle: mappedVehicle,
        memberType: mappedMemberType,
        status: mappedStatus
      } as User;
    }));

    return usersWithVehicles;
  }

  async addUser(user: Partial<User>): Promise<void> {
    const data = {
      ...user,
      createdAt: serverTimestamp()
    };
    delete data.id;
    await addDoc(collection(db, this.collectionName), data);
  }

  async updateUser(userId: string, data: Partial<User>): Promise<void> {
    const userRef = doc(db, this.collectionName, userId);
    await updateDoc(userRef, data);
  }

  async deleteUser(userId: string): Promise<void> {
    const userRef = doc(db, this.collectionName, userId);
    await deleteDoc(userRef);
  }
}
