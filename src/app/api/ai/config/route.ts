import {NextRequest,NextResponse} from 'next/server';
import {getSession,newSession,publicSettings,sameOrigin,providers,cookieName,Provider} from '@/services/ai/session';
import {groqModels} from '@/services/ai/groq-models';
import {generateJSON} from '@/services/ai/provider';
export const runtime='nodejs';
export async function GET(req:NextRequest){return NextResponse.json(publicSettings(getSession(req)),{headers:{'Cache-Control':'no-store'}})}
export async function POST(req:NextRequest){
 if(!sameOrigin(req))return NextResponse.json({error:'Yêu cầu cấu hình không hợp lệ.'},{status:403});
 try{const raw=await req.text();if(raw.length>5000)throw Error('Cấu hình quá dài.');const body=JSON.parse(raw);if(!providers.includes(body.provider))throw Error('Chọn nhà cung cấp hợp lệ.');const provider=body.provider as Provider;let model=String(body.model||'').trim();const key=typeof body.key==='string'?body.key.trim():'';
 if(!body.remove&&((!model&&provider!=='groq')||model.length>150||(model&&!/^[-a-zA-Z0-9_./:]+$/.test(model))))throw Error('Nhập tên model hợp lệ.');if(key&&(key.length<10||key.length>1024||/\s/.test(key)))throw Error('API key không hợp lệ.');
 let session=getSession(req);if(!body.remove&&!key&&!session?.credentials[provider]?.key)throw Error('Nhập API key cho nhà cung cấp này.');const effectiveKey=key||session?.credentials[provider]?.key;
 let models:string[]|undefined;
 if(!body.remove&&provider==='groq'&&(body.listModels||!model)){
 models=await groqModels(effectiveKey!);
 if(!models.length)throw Error('Không tìm thấy model trò chuyện khả dụng trong Groq.');
 if(body.listModels)return NextResponse.json({models,suggested:models[0]},{headers:{'Cache-Control':'no-store'}});
 model=models[0];
 }
 if(!body.remove&&body.test){await generateJSON({provider,key:effectiveKey!,model},'Chỉ trả JSON object {"text":"Kết nối thành công"}.','Kiểm tra kết nối CRM');}
 let id:string|undefined;if(!session){const made=newSession();session=made.session;id=made.id}
 if(body.remove)delete session.credentials[provider];else {session.credentials[provider]={key:key||session.credentials[provider]!.key,model};session.active=provider}
 const res=NextResponse.json({...publicSettings(session),tested:!!body.test},{headers:{'Cache-Control':'no-store'}});if(id)res.cookies.set(cookieName,id,{httpOnly:true,sameSite:'strict',secure:req.nextUrl.protocol==='https:',path:'/',maxAge:86400});return res;
 }catch(e){return NextResponse.json({error:e instanceof SyntaxError?"Cấu hình không đúng định dạng.":(e as Error).message},{status:400})}
}


