import type {Metadata,Viewport} from 'next';
import './globals.css';
import {StoreProvider} from '@/services/repository/context';
export const metadata:Metadata={title:'LẮM AI CRM · Bất động sản',description:'Quỹ hàng, khách hàng và công việc trong một không gian.',manifest:'/manifest.webmanifest',icons:{icon:'/favicon.svg',apple:'/icon-192.png'},appleWebApp:{capable:true,statusBarStyle:'default',title:'Lắm CRM'}};
export const viewport:Viewport={width:'device-width',initialScale:1,viewportFit:'cover',themeColor:'#087866'};
export default function Layout({children}:{children:React.ReactNode}){return <html lang="vi"><body><StoreProvider>{children}</StoreProvider></body></html>}
