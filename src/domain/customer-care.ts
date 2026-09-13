import {Database,Customer,Task} from './models';
export function customerLink(id:string){return '#customers?customer='+encodeURIComponent(id)}
export function contactLinks(c:Customer){
 const phone=(c.phone||'').replace(/[^+\d]/g,'');
 const raw=(c.zalo||c.phone||'').trim();
 const number=raw.replace(/[\s().-]/g,'');
 let zalo='';
 if(/^\+?\d{8,15}$/.test(number))zalo='https://zalo.me/'+number.replace(/^\+84/,'0');
 else try{const url=new URL(raw);if(url.protocol==='https:'&&url.hostname==='zalo.me')zalo=url.href}catch{}
 return {phone:/^\+?\d{8,15}$/.test(phone)?'tel:'+phone:'',zalo};
}
export function pendingCustomers(d:Database,now=Date.now()){
 return d.customers.flatMap(customer=>{
  if(['Đã giao dịch','Tạm dừng'].includes(customer.status))return [];
  const tasks=d.tasks.filter(t=>t.customerId===customer.id&&t.status==='TODO');
  const searching=d.requirements.some(r=>r.customerId===customer.id&&r.status==='ACTIVE')||customer.status==='Đang tìm';
  if(!searching&&!tasks.length)return [];
  const due=tasks.filter(t=>t.dueAt).sort((a,b)=>Date.parse(a.dueAt!)-Date.parse(b.dueAt!))[0];
  const overdue=!!due&&Date.parse(due.dueAt!)<=now;
  return [{customer,tasks,due,overdue,searching}];
 }).sort((a,b)=>Number(b.overdue)-Number(a.overdue)||Number(!b.tasks.length)-Number(!a.tasks.length)||(Date.parse(a.due?.dueAt||'2099-01-01')-Date.parse(b.due?.dueAt||'2099-01-01')));
}
export function recordCare(d:Database,input:{customerId:string;propertyId?:string;type:Task['type'];note:string;nextAt?:string;completeTaskId?:string},now=new Date().toISOString()){
 const customer=d.customers.find(c=>c.id===input.customerId);
 if(!customer)throw Error('Không tìm thấy khách hàng');
 if(!input.note.trim())throw Error('Nhập kết quả hoặc ghi chú chăm sóc');
 if(input.nextAt&&(!Number.isFinite(Date.parse(input.nextAt))||Date.parse(input.nextAt)<=Date.parse(now)))throw Error('Lịch chăm sóc tiếp theo phải ở tương lai');
 if(input.propertyId&&!d.properties.some(p=>p.id===input.propertyId))throw Error('Không tìm thấy BĐS');
 const existing=input.completeTaskId?d.tasks.find(t=>t.id===input.completeTaskId&&t.customerId===customer.id&&t.status==='TODO'):undefined;
 if(input.completeTaskId&&!existing)throw Error('Công việc đã thay đổi, vui lòng chọn lại');
 if(existing){existing.status='DONE';existing.completedAt=now;existing.note=[existing.note,input.note.trim()].filter(Boolean).join('\n');}
 else d.tasks.unshift({id:crypto.randomUUID(),title:'Chăm sóc '+customer.name,type:input.type,customerId:customer.id,propertyId:input.propertyId,status:'DONE',priority:customer.priority,note:input.note.trim(),completedAt:now});
 if(input.nextAt)d.tasks.unshift({id:crypto.randomUUID(),title:'Chăm sóc tiếp '+customer.name,type:'FOLLOW_UP',customerId:customer.id,propertyId:input.propertyId||existing?.propertyId,status:'TODO',priority:customer.priority,dueAt:input.nextAt,note:input.note.trim()});
 customer.updatedAt=now;
}
