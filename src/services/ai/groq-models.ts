export async function groqModels(key:string,fetcher:typeof fetch=fetch):Promise<string[]> {
 const r=await fetcher('https://api.groq.com/openai/v1/models',{headers:{Authorization:`Bearer ${key}`},signal:AbortSignal.timeout(15000)});
 if(!r.ok){if(r.status===401||r.status===403)throw Error('Groq từ chối API key. Kiểm tra key và quyền trong Groq Console.');if(r.status===429)throw Error('Groq đang giới hạn yêu cầu. Thử lại sau.');throw Error('Không tải được danh sách model Groq.')}
 const body=await r.json();const ids=(body.data||[]).filter((m:any)=>m.active!==false&&typeof m.id==='string').map((m:any)=>m.id as string).filter((id:string)=>!/(whisper|tts|orpheus|guard|compound|embed)/i.test(id));
 const preference=['openai/gpt-oss-20b','openai/gpt-oss-120b','llama-3.3-70b-versatile','llama-3.1-8b-instant'];
 return [...new Set<string>(ids)].sort((a,b)=>{const rank=(id:string)=>{const n=preference.indexOf(id);return n<0?100:n};return rank(a)-rank(b)||a.localeCompare(b)});
}
