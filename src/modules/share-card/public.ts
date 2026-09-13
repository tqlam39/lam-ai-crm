import {doc,setDoc,getDoc,deleteDoc} from 'firebase/firestore';
import {db,auth} from '@/services/firebase/client';
import {Property,Settings} from '@/domain/models';
export type PublicCard={title:string;type:Property['type'];ward:string;province:string;width:number;length:number;direction:Property['direction'];bedrooms:number;amount:number;transactionType:Property['transactionType'];image:string;brand:string;phone:string;userId:string};
export async function createPublicCard(p:Property,s:Settings){if(!db||!auth?.currentUser)throw Error('Cần đăng nhập Google để tạo link công khai.');const id=crypto.randomUUID();const value:PublicCard={title:p.title,type:p.type,ward:p.location.wardCommune,province:p.location.provinceCity,width:p.dimensions.width,length:p.dimensions.length,direction:p.direction,bedrooms:p.bedrooms,amount:p.price.amount,transactionType:p.transactionType,image:p.media.images[0].url,brand:s.brand,phone:s.phone,userId:auth.currentUser.uid};await setDoc(doc(db,'publicShares',id),value);return `${location.origin}/share/${id}`}
export async function getPublicCard(id:string):Promise<PublicCard|null>{if(!db)return null;const snap=await getDoc(doc(db,'publicShares',id));return snap.exists()?snap.data() as PublicCard:null}
export async function revokePublicCard(id:string){if(!db)throw Error('Chưa kết nối');await deleteDoc(doc(db,'publicShares',id))}
