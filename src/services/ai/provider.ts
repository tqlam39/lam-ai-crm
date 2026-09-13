import type {Credential,Provider} from './session';
export async function generateJSON(config:Credential & {provider:Provider},instruction:string,input:any,fetcher:typeof fetch=fetch){
 const text=JSON.stringify(input?.image?{text:input.text}:input);
 if(input?.image&&!/^image\/(jpeg|png|webp)$/.test(input.image.mimeType))throw Error('Ảnh phải là JPEG, PNG hoặc WebP.');
 let url:string,headers:Record<string,string>,payload:unknown;
 if(config.provider==='gemini'){
 url=`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(config.model)}:generateContent`;
 headers={'Content-Type':'application/json','x-goog-api-key':config.key};
 payload={systemInstruction:{parts:[{text:instruction}]},contents:[{role:'user',parts:[{text},...(input?.image?[{inlineData:input.image}]:[])]}],generationConfig:{responseMimeType:'application/json',temperature:0.1}};
 }else{
 url=config.provider==='openai'?'https://api.openai.com/v1/chat/completions':'https://api.groq.com/openai/v1/chat/completions';
 headers={'Content-Type':'application/json',Authorization:`Bearer ${config.key}`};
 const content=input?.image?[{type:'text',text},{type:'image_url',image_url:{url:`data:${input.image.mimeType};base64,${input.image.data}`}}]:text;
 payload={model:config.model,messages:[{role:'system',content:instruction+' Chỉ trả về một JSON object hợp lệ.'},{role:'user',content}],response_format:{type:'json_object'},...(config.provider==='openai'?{store:false}:{})};
 }
 const r=await fetcher(url,{method:'POST',headers,body:JSON.stringify(payload),signal:AbortSignal.timeout(45000)});
 if(!r.ok){if(r.status===401||r.status===403)throw Error('API key không hợp lệ hoặc chưa có quyền dùng model.');if(r.status===429)throw Error('Đã hết hạn mức AI hoặc gửi quá nhanh. Vui lòng thử lại sau.');if(r.status===400||r.status===404)throw Error('Kiểm tra tên model và khả năng hỗ trợ JSON/ảnh của model.');throw Error('Nhà cung cấp AI tạm thời không khả dụng.')}
 const body=await r.json();const output=config.provider==='gemini'?body.candidates?.[0]?.content?.parts?.map((p:any)=>p.text||'').join(''):body.choices?.[0]?.message?.content;
 if(typeof output!=='string')throw Error('AI không trả nội dung.');try{const parsed=JSON.parse(output);if(!parsed||typeof parsed!=='object'||Array.isArray(parsed))throw Error();return parsed}catch{throw Error('AI trả dữ liệu không đúng định dạng JSON. Vui lòng thử lại.')}
}
