import {auth} from '@/services/firebase/client';
export interface AIProvider {parseProperty(input:unknown):Promise<any>;parseRequirement(text:string):Promise<any>;explainMatch(input:unknown):Promise<any>;generateListing(input:unknown):Promise<any>;summarizeCustomer(input:unknown):Promise<any>}
async function request(action:string,input:unknown){const token=await auth?.currentUser?.getIdToken();const res=await fetch('/api/ai',{method:'POST',headers:{'Content-Type':'application/json',...(token?{Authorization:`Bearer ${token}`}:{})},body:JSON.stringify({action,input})});const data=await res.json();if(!res.ok)throw Error(data.error||'AI chưa phản hồi, vui lòng thử lại.');return data.result}
export const aiProvider:AIProvider={parseProperty:input=>request('parseProperty',input),parseRequirement:input=>request('parseRequirement',input),explainMatch:input=>request('explainMatch',input),generateListing:input=>request('generateListing',input),summarizeCustomer:input=>request('summarizeCustomer',input)};
export const askCopilot=(input:unknown)=>request('copilot',input);

