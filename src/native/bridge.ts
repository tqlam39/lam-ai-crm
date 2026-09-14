import {Capacitor,registerPlugin} from '@capacitor/core';
export const isAndroid=Capacitor.getPlatform()==='android';
export const NativeCRM=registerPlugin<any>('NativeCRM');
export async function saveDocument(name:string,text:string,mime='application/json'){if(isAndroid){await NativeCRM.exportDocument({name,text,mime});return}const url=URL.createObjectURL(new Blob([text],{type:mime}));const a=document.createElement('a');a.href=url;a.download=name;a.click();setTimeout(()=>URL.revokeObjectURL(url),1000)}
