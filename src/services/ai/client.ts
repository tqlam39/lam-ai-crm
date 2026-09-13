export async function readAIConfig(){const r=await fetch('/api/ai/config',{cache:'no-store'});if(!r.ok)throw Error('Không đọc được cấu hình AI.');return r.json()}
export async function saveAIConfig(value:{provider:string;model?:string;key?:string;remove?:boolean;listModels?:boolean;test?:boolean}){const r=await fetch('/api/ai/config',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(value)});const data=await r.json();if(!r.ok)throw Error(data.error||'Không lưu được cấu hình');return data}

