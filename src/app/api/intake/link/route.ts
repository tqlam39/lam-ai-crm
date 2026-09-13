import {NextRequest,NextResponse} from 'next/server';
import {sameOrigin} from '@/services/ai/session';
import {readPublicLink} from '@/services/intake/public-link';
export const runtime='nodejs';
let windowStart=0,count=0;
export async function POST(req:NextRequest){if(!sameOrigin(req))return NextResponse.json({error:'Yêu cầu không hợp lệ.'},{status:403});try{
 if(Date.now()-windowStart>60000){windowStart=Date.now();count=0}if(++count>20)return NextResponse.json({error:'Đọc link quá nhanh. Vui lòng đợi một phút.'},{status:429});
 const raw=await req.text();if(raw.length>5000)throw Error('Link quá dài.');const body=JSON.parse(raw);if(typeof body.url!=='string'||body.url.length>2048)throw Error('Nhập link hợp lệ.');return NextResponse.json(await readPublicLink(body.url),{headers:{'Cache-Control':'no-store'}});
 }catch(e){const message=(e as Error).message;return NextResponse.json({error:/^(Chỉ |Không |Link |Trang |Website |Facebook )/.test(message)?message:'Không đọc được website. Hãy dán nội dung hoặc chọn screenshot.'},{status:400})}}
