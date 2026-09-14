import {takePropertyPhoto} from '@/native/camera';
'use client';
import {useState} from 'react';
import {Sparkles,Send,ImagePlus,Mic,Camera,Link as LinkIcon,Square} from 'lucide-react';
import {useStore} from '@/services/repository/context';
import {aiProvider,askCopilot} from '@/services/gemini';
import {PropertyForm} from '@/modules/properties/form';
import {RequirementForm} from '@/modules/customers';
import {matchProperty} from '@/domain/engines';
import {propertyIntakeDraft} from '@/domain/property-intake';
import {importPublicLink,prepareIntakeImage} from '@/services/intake/client';
import {useVoiceIntake} from '@/services/intake/useVoiceIntake';
export default function Copilot(){
 const {data,notify,mode}=useStore();
 const [text,setText]=useState('');const [type,setType]=useState('property');
 const [image,setImage]=useState<{mimeType:string;data:string}|null>(null);const [imageName,setImageName]=useState('');
 const [waiting,setWaiting]=useState(false);const [answer,setAnswer]=useState('');const [draft,setDraft]=useState<any>(null);const [requirement,setRequirement]=useState<any>(null);
 const [link,setLink]=useState('');const [sourceUrl,setSourceUrl]=useState('');const [importing,setImporting]=useState(false);const [sourceMessage,setSourceMessage]=useState('');
 const voice=useVoiceIntake(value=>setText(old=>old+(old?'\n':'')+value),notify);
 async function readLink(){if(!link.trim()){setSourceMessage('Nhập link web hoặc link bài Facebook công khai.');return}setImporting(true);setSourceMessage('');try{const result=await importPublicLink(link.trim());setText(old=>old+(old?'\n\n':'')+result.text);setSourceUrl(result.url);setSourceMessage('Đã lấy nội dung'+(result.title?' từ '+result.title:'')+'. Kiểm tra nội dung bên dưới trước khi phân tích.'+(result.truncated?' Nội dung dài đã giới hạn 30.000 ký tự.':''))}catch(e){setSourceMessage((e as Error).message)}finally{setImporting(false)}}
 async function chooseImage(file?:File){if(!file)return;setImporting(true);try{setImage(await prepareIntakeImage(file));setImageName(file.name);setSourceMessage('Đã chọn ảnh. Nhấn Phân tích để AI đọc thông tin. Model đang chọn cần hỗ trợ ảnh.')}catch(e){notify((e as Error).message)}finally{setImporting(false)}}
 async function run(){
 if(!text.trim()&&!image){notify('Nhập nội dung, đọc link, chọn ảnh hoặc dùng giọng nói.');return}if(type!=='property'&&image&&!text.trim()){notify('Để trích xuất ảnh, chọn Nhập tin BĐS. Các mục khác cần nội dung văn bản.');return}
 setWaiting(true);setAnswer('');const inputText=text;const inputImage=image;const inputSource=sourceUrl;
 try{
 if(type==='property'){const result=await aiProvider.parseProperty({text:inputText,image:inputImage});setDraft(propertyIntakeDraft(result,inputText,inputSource))}
 else if(type==='requirement'||type==='search'){
 const r=await aiProvider.parseRequirement(inputText);if(type==='requirement')setRequirement({...r,id:crypto.randomUUID(),customerId:'',status:'ACTIVE',rawRequirementText:inputText});
 else{const results=data.properties.filter(p=>matchProperty(p,{...r,id:'search',customerId:'',status:'ACTIVE'}).eligible);setAnswer(results.length?results.map(p=>`${p.code} · ${p.title}`).join('\n'):'Không có sản phẩm đáp ứng đủ điều kiện.')}
 }else{const result=await askCopilot({question:inputText,context:{tasks:data.tasks.filter(t=>t.status==='TODO').slice(0,15).map(t=>({title:t.title,dueAt:t.dueAt,priority:t.priority})),counts:{properties:data.properties.length,customers:data.customers.length,requirements:data.requirements.length}}});setAnswer(result.text)}
 }catch(e){setAnswer((e as Error).message)}finally{setWaiting(false)}
 }
 return <><div className="page-heading"><div><p className="eyebrow">TRỢ LÝ BẤT ĐỘNG SẢN</p><h1>AI Sales Copilot <Sparkles className="inline-icon"/></h1></div><a className="badge green" href="#settings">Cấu hình AI</a></div>
 <div className="ai-workspace"><div className="ai-welcome"><div className="ai-orb"><Sparkles size={32}/></div><h2>Nhập một lần, AI điền thông tin.</h2><p>Dán nội dung, đọc link, chụp ảnh hoặc nói bằng tiếng Việt.</p></div>
 <div className="ai-modes">{[['property','Nhập tin BĐS'],['requirement','Nhập nhu cầu'],['search','Tìm bằng ngôn ngữ tự nhiên'],['copilot','Hỏi về công việc']].map(([k,v])=><button disabled={waiting} className={'chip '+(type===k?'active':'')} key={k} onClick={()=>setType(k)}>{v}</button>)}</div>
 <section className="panel quick-intake"><h3>Nhập liệu nhanh</h3><label className="field"><span>Link web / bài viết Facebook công khai</span><div className="intake-link-row"><input type="url" value={link} disabled={importing} placeholder="https://…" onChange={e=>setLink(e.target.value)} onKeyDown={e=>{if(e.key==='Enter'){e.preventDefault();if(!importing&&!waiting)readLink()}}}/><button className="secondary" disabled={importing||waiting} onClick={readLink}><LinkIcon size={17}/>{importing?'Đang đọc…':'Đọc nội dung'}</button></div></label>
 <div className="intake-buttons"><button className="secondary" disabled={importing||waiting} onClick={()=>takePropertyPhoto().then(chooseImage).catch(e=>notify(e.message))}><Camera size={19}/>Camera</button><label className="secondary"><ImagePlus size={19}/>Chọn ảnh<input className="visually-hidden" aria-label="Chọn ảnh hoặc screenshot để AI trích xuất" type="file" accept="image/*" disabled={importing||waiting} onChange={e=>{chooseImage(e.target.files?.[0]);e.target.value=''}}/></label><button className={voice.listening?'primary':'secondary'} disabled={waiting} onClick={voice.toggle}>{voice.listening?<Square size={17}/>:<Mic size={19}/>} {voice.listening?'Dừng ghi giọng nói':'Nhập bằng giọng nói'}</button></div>
 {voice.listening&&<p role="status" className="notice">Đang nghe tiếng Việt… {voice.interim}</p>}{sourceMessage&&<p role="status" className="notice">{sourceMessage}</p>}
 <p className="muted">Link phải đọc được mà không đăng nhập. Facebook hoặc trang tải bằng JavaScript có thể chặn đọc tự động; khi đó hãy dán nội dung hoặc chọn screenshot.</p>
 </section>
 <div className="ai-input"><label className="intake-text-label" htmlFor="ai-intake-text">Nội dung để AI trích xuất</label><textarea id="ai-intake-text" disabled={waiting} placeholder={type==='property'?'Dán hoặc nhập toàn bộ thông tin bất động sản tại đây…':'Ví dụ: tìm nhà từ 1 đến 1,5 tỷ, ít nhất 3 phòng ngủ…'} value={text} onChange={e=>setText(e.target.value)} rows={9}/>
 {image&&<div className="intake-image-preview"><img src={`data:${image.mimeType};base64,${image.data}`} alt="Ảnh đầu vào AI"/><div><p>{imageName}</p><button className="text-button" disabled={waiting} onClick={()=>{setImage(null);setImageName('')}}>Bỏ ảnh</button></div></div>}
 {sourceUrl&&<p className="intake-source">Nguồn: {sourceUrl}<button className="text-button" disabled={waiting} onClick={()=>setSourceUrl('')}>Bỏ liên kết nguồn</button></p>}
 <div className="ai-input-footer"><span className="muted">{type==='property'?'Nội dung này sẽ được giữ trong Thông tin chi tiết.':'Xem lại nội dung trước khi phân tích.'}</span><button className="primary" disabled={waiting||importing||voice.listening} onClick={run}>{waiting?'Đang phân tích…':'Phân tích'}<Send size={17}/></button></div></div>
 {answer&&<div className="ai-answer" role="status">{answer}</div>}<p className="ai-note">AI tạo bản nháp để bạn kiểm tra. Với đầu vào chỉ có ảnh, AI chép nội dung đọc được vào Thông tin chi tiết. Ảnh trích xuất không tự trở thành ảnh đại diện BĐS.</p>
 {mode==='local'&&<div className="notice">Chọn GPT, Groq hoặc Gemini trong Cài đặt → API key. Key lưu an toàn trên điện thoại; AI cần mạng.</div>}</div>
 {draft&&<PropertyForm initial={draft} onClose={()=>setDraft(null)}/>} {requirement&&<RequirementForm initial={requirement} onClose={()=>setRequirement(null)}/>}</>;
}
