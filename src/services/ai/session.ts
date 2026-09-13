import {randomBytes} from 'node:crypto';
import type {NextRequest} from 'next/server';
export const providers=['gemini','openai','groq'] as const;
export type Provider=typeof providers[number];
export type Credential={key:string;model:string};
type Session={active:Provider;credentials:Partial<Record<Provider,Credential>>;expires:number;count:number;window:number};
const store=globalThis as typeof globalThis & {crmAISessions?:Map<string,Session>};
const sessions=store.crmAISessions??=new Map<string,Session>();
export const cookieName='crm-ai-session';
export function sameOrigin(req:NextRequest){const origin=req.headers.get('origin');if(!origin||!req.headers.get('content-type')?.startsWith('application/json'))return false;try{const parsed=new URL(origin);return parsed.origin===origin&&['http:','https:'].includes(parsed.protocol)&&parsed.host===(req.headers.get('host')||req.nextUrl.host)}catch{return false}}
export function getSession(req:NextRequest){const id=req.cookies.get(cookieName)?.value;const s=id?sessions.get(id):undefined;if(s&&s.expires>Date.now())return s;if(id)sessions.delete(id);return undefined}
export function newSession(){for(const [id,s]of sessions)if(s.expires<=Date.now())sessions.delete(id);if(sessions.size>=100)throw Error('Máy chủ đang bận.');const id=randomBytes(32).toString('hex');const session:Session={active:'openai',credentials:{},expires:Date.now()+86400000,count:0,window:Date.now()};sessions.set(id,session);return {id,session}}
export function publicSettings(s?:Session){return {active:s?.active||'openai',providers:Object.fromEntries(providers.map(p=>[p,{configured:!!s?.credentials[p]?.key,model:s?.credentials[p]?.model||''}]))}}
export function configuredCredential(req:NextRequest){const s=getSession(req);if(!s)return null;const c=s.credentials[s.active];if(!c)return null;if(Date.now()-s.window>60000){s.count=0;s.window=Date.now()}if(s.count>=10)throw Error('Tối đa 10 yêu cầu/phút.');s.count++;return {provider:s.active,...c}}

