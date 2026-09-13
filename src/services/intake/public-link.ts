import {lookup} from 'node:dns/promises';
import {isIP} from 'node:net';
import http from 'node:http';
import https from 'node:https';
export function isPublicAddress(address:string):boolean {
 if(isIP(address)===4){const [a,b]=address.split('.').map(Number);return !(a===0||a===10||a===127||a>=224||(a===100&&b>=64&&b<=127)||(a===169&&b===254)||(a===172&&b>=16&&b<=31)||(a===192&&(b===168||b===0||b===2))||(a===198&&(b===18||b===19||b===51))||(a===203&&b===0));}
 if(isIP(address)===6)return /^[23][0-9a-f]{3}:/i.test(address)&&!/^2001:(db8|0|0000):/i.test(address)&&!/^2002:/i.test(address);
 return false;
}
export function publicURL(value:string){const url=new URL(value);if(!['http:','https:'].includes(url.protocol)||url.username||url.password||(url.port&&!['80','443'].includes(url.port)))throw Error('Chỉ hỗ trợ link web HTTP/HTTPS công khai.');const host=url.hostname.replace(/^\[|\]$/g,'');if(host==='localhost'||host.endsWith('.localhost')||host.endsWith('.local')||(isIP(host)&&!isPublicAddress(host)))throw Error('Không đọc được địa chỉ nội bộ.');url.hash='';return url}
async function download(url:URL):Promise<{status:number;location?:string;contentType:string;text:string}>{
 const hostname=url.hostname.replace(/^\[|\]$/g,'');const addresses=await lookup(hostname,{all:true});if(!addresses.length||addresses.some(a=>!isPublicAddress(a.address)))throw Error('Link phải trỏ đến một website công khai.');const chosen=addresses[0];
 return new Promise((resolve,reject)=>{
 const request=(url.protocol==='https:'?https:http).request(url,{method:'GET',agent:false,family:chosen.family,lookup:(_host,options,callback:any)=>{if(typeof options==='object'&&options.all)callback(null,[chosen]);else callback(null,chosen.address,chosen.family)},headers:{Accept:'text/html,text/plain','Accept-Encoding':'identity','User-Agent':'LamCRM-LinkPreview/1.0'}},response=>{
  const status=response.statusCode||0;if(status>=300&&status<400){response.resume();finish();resolve({status,location:response.headers.location,contentType:'',text:''});return}
  const contentType=String(response.headers['content-type']||'');if(!/text\/(html|plain)/i.test(contentType)){response.destroy();finish();reject(Error('Link này không phải trang văn bản. Hãy dán nội dung hoặc chọn ảnh.'));return}
  const chunks:Buffer[]=[];let size=0;response.on('data',(chunk:Buffer)=>{size+=chunk.length;if(size>2_000_000){response.destroy();request.destroy(Error('Trang quá lớn. Hãy sao chép nội dung tin để nhập.'))}else chunks.push(chunk)});response.on('end',()=>{finish();resolve({status,contentType,text:Buffer.concat(chunks).toString('utf8')})});response.on('error',error=>{finish();reject(error)});
 });const timer=setTimeout(()=>request.destroy(Error('Website phản hồi quá chậm. Hãy dán nội dung hoặc chọn screenshot.')),15000);function finish(){clearTimeout(timer)}request.on('error',error=>{finish();reject(error)});request.end();
 });
}
function decode(value:string){const entities:Record<string,string>={amp:'&',lt:'<',gt:'>',quot:'"',apos:"'",nbsp:' '};return value.replace(/&(#x[\da-f]+|#\d+|amp|lt|gt|quot|apos|nbsp);/gi,(_,code:string)=>{if(code[0]!=='#')return entities[code.toLowerCase()]||'';const n=code[1].toLowerCase()==='x'?parseInt(code.slice(2),16):parseInt(code.slice(1),10);return n>0&&n<=0x10ffff?String.fromCodePoint(n):''})}
export function readableHTML(html:string){
 const cleaned=html.replace(/<!--[\s\S]*?-->/g,'').replace(/<(script|style|noscript|nav|footer|header|form)\b[^>]*>[\s\S]*?<\/\1>/gi,'');
 const title=decode(cleaned.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1]||'').replace(/<[^>]+>/g,'').trim();
 const region=cleaned.match(/<(?:article|main)\b[^>]*>([\s\S]*?)<\/(?:article|main)>/i)?.[1]||cleaned.match(/<body[^>]*>([\s\S]*?)<\/body>/i)?.[1]||cleaned;
 const metas=[...cleaned.matchAll(/<meta\b[^>]*>/gi)].filter(m=>/(?:og:description|name\s*=\s*["']description)/i.test(m[0])).map(m=>decode(m[0].match(/content\s*=\s*"([^"]*)"/i)?.[1]||m[0].match(/content\s*=\s*'([^']*)'/i)?.[1]||''));
 const text=decode(region.replace(/<(br|\/p|\/div|\/li|\/h[1-6])\b[^>]*>/gi,'\n').replace(/<[^>]*>/g,' ')).replace(/[ \t]+/g,' ').replace(/\n\s*\n/g,'\n\n').trim();
 return {title,text:[...new Set([...metas.filter(Boolean),text])].join('\n\n').slice(0,30000)};
}
export async function readPublicLink(value:string){let url=publicURL(value);for(let hop=0;hop<4;hop++){
 const result=await download(url);if(result.status>=300&&result.status<400){if(!result.location)break;url=publicURL(new URL(result.location,url).href);continue}
 if(result.status!==200)throw Error('Trang không cho phép đọc công khai hoặc yêu cầu đăng nhập. Hãy dán nội dung hoặc chọn screenshot.');
 if(/facebook\.com$|fb\.com$/i.test(url.hostname)&&/\/login|\/checkpoint/i.test(url.pathname))throw Error('Facebook yêu cầu đăng nhập. Hãy dán nội dung bài hoặc ảnh chụp.');
 const parsed=/html/i.test(result.contentType)?readableHTML(result.text):{title:'',text:result.text.slice(0,30000)};
 if(parsed.text.length<60||(/facebook\.com$|fb\.com$/i.test(url.hostname)&&/log in or sign up|log into facebook|đăng nhập hoặc đăng ký|you must log in/i.test(parsed.title+' '+parsed.text.slice(0,500))))throw Error('Không lấy được nội dung bài công khai. Hãy dán nội dung bài hoặc ảnh chụp.');
 return {...parsed,url:url.href,truncated:parsed.text.length>=30000};
 }throw Error('Link chuyển hướng quá nhiều. Hãy dùng link trực tiếp đến bài viết.')}

