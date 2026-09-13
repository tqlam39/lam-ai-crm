'use client';
import {createContext,useContext,useState,useEffect,ReactNode,useRef} from 'react';
import {Database} from '@/domain/models';
import {emptyDatabase,demoDatabase} from './demo';
import {loadLocal,saveLocal,loadCloud,saveCloud} from './index';
import {watchAuth,logout} from '@/services/firebase/client';
type Store={data:Database;ready:boolean;busy:boolean;error:string;mode:'local'|'cloud';user:string;commit:(fn:(d:Database)=>void,entity:string,action:string)=>Promise<void>;loadDemo:()=>Promise<void>;notify:(message:string)=>void;message:string;signOut:()=>Promise<void>};
const Context=createContext<Store>(null!);
export function StoreProvider({children}:{children:ReactNode}){const [data,setData]=useState(emptyDatabase);const [ready,setReady]=useState(false);const [busy,setBusy]=useState(false);const [error,setError]=useState('');const [user,setUser]=useState('');const [message,notify]=useState('');const current=useRef(data);const locked=useRef(false);const epoch=useRef(0);
useEffect(()=>{try{const d=loadLocal();current.current=d;setData(d)}catch{setError('Không đọc được dữ liệu trên máy. Hãy kiểm tra bản sao lưu.')}setReady(true);return watchAuth(async u=>{const generation=++epoch.current;setReady(false);setUser(u?.uid||'');try{const next=u?await loadCloud(u.uid):loadLocal();if(generation!==epoch.current)return;current.current=next;setData(next);setError('')}catch(e){setError(String(e));current.current=emptyDatabase();setData(current.current)}finally{if(generation===epoch.current)setReady(true)}})},[]);
useEffect(()=>{if(message){const t=setTimeout(()=>notify(''),4500);return()=>clearTimeout(t)}},[message]);
async function commit(fn:(d:Database)=>void,entity:string,action:string){if(user&&error)throw Error('Chưa đọc được dữ liệu đám mây. Tải lại app trước khi sửa.');if(locked.current)throw Error('Đang lưu, vui lòng đợi.');locked.current=true;setBusy(true);const generation=epoch.current;try{const previous=current.current;const next=structuredClone(previous);fn(next);next.activities.unshift({id:crypto.randomUUID(),entityId:entity,action,at:new Date().toISOString()});if(user)await saveCloud(user,previous,next);else saveLocal(next);if(generation===epoch.current){current.current=next;setData(next);notify('Đã lưu')}}catch(e){notify('Chưa lưu: '+(e as Error).message);throw e}finally{locked.current=false;setBusy(false)}}
return <Context.Provider value={{data,ready,busy,error,mode:user?'cloud':'local',user,commit,notify,message,signOut:logout,loadDemo:()=>commit(d=>{const demo=demoDatabase();for(const k of ['properties','customers','requirements','tasks'] as const)(d[k] as unknown[]).push(...demo[k].filter(x=>!d[k].some(y=>y.id===x.id)))},'demo','Nạp dữ liệu minh họa')}}>{children}</Context.Provider>}
export const useStore=()=>useContext(Context);

