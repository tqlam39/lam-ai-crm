import assert from 'node:assert/strict';
import test from 'node:test';
import {propertySchema} from '../src/domain/models';
import {duplicateCandidates,matchProperty,normalizeProperty} from '../src/domain/engines';
import {demoDatabase} from '../src/services/repository/demo';
import {publicText} from '../src/modules/share-card/service';
const data=demoDatabase();const p=data.properties[0];const r=data.requirements[0];
test('Required fields reject missing direction, owner, dimensions, price and media',()=>{for(const candidate of [{...p,direction:''},{...p,owner:{name:''}},{...p,dimensions:{width:0,length:20}},{...p,price:{amount:0,unit:'VND'}},{...p,media:{images:[]}}])assert.equal(propertySchema.safeParse(candidate).success,false)});
test('Land requires zero bedrooms',()=>{assert.equal(propertySchema.safeParse({...p,type:'LAND',bedrooms:2}).success,false)});
test('Sold preserves listing price and requires sale details',()=>{assert.equal(propertySchema.safeParse({...p,status:'SOLD'}).success,false);assert.equal(propertySchema.safeParse({...p,status:'SOLD',soldInfo:{soldAt:'2026-09-13',actualSoldPrice:1400000000}}).success,true);assert.equal(p.price.amount,1450000000)});
test('Hard constraints override scoring in both matching directions',()=>{assert.equal(matchProperty(p,r).eligible,true);for(const criterion of [{priceMax:1},{bedroomsMin:9},{wardCommunes:['Khác']},{directions:['S']},{widthMin:100},{lengthMin:100},{areaMin:1000},{areaMax:1},{transactionType:'RENT' as const},{provinceCities:['Khác']},{propertyTypes:['LAND']}])assert.equal(matchProperty(p,{...r,...criterion}).eligible,false);assert.equal(matchProperty({...p,road:undefined},r).eligible,false);assert.equal(matchProperty({...p,status:'SOLD'},r).eligible,false)});
test('No criteria does not imply 100 percent match',()=>assert.equal(matchProperty(p,{id:'empty',customerId:'c',status:'ACTIVE'}).score,0));
test('Near duplicate found regardless of ID',()=>{assert.ok(duplicateCandidates({...p,id:'new'},[p]).length);assert.equal(duplicateCandidates(p,[p]).length,0)});
test('Area and price per square metre derived consistently',()=>{const n=normalizeProperty(p);assert.equal(n.dimensions.calculatedArea,120);assert.equal(n.price.pricePerM2,p.price.amount/120)});
test('Public sharing excludes private owner and phone',()=>{const card=publicText({...p,owner:{name:'PRIVATE OWNER',phone:'PRIVATE PHONE'}},data.settings);assert.ok(!card.includes('PRIVATE OWNER'));assert.ok(!card.includes('PRIVATE PHONE'));assert.ok(card.includes(data.settings.phone))});

import {billionsToVnd,vndToBillions} from '../src/domain/property-price';
test('Price input accepts Vietnamese decimals and persists exact VND',()=>{
 assert.equal(billionsToVnd('1,5'),1500000000);
 assert.equal(billionsToVnd('1.29'),1290000000);
 assert.equal(billionsToVnd('0,85'),850000000);
 assert.equal(billionsToVnd('0,000000001'),1);
 assert.equal(billionsToVnd(''), '');
 assert.equal(vndToBillions(1450000000),'1,45');
 assert.equal(vndToBillions(1000000000000),'1000');
 for(const amount of [1,850000000,1290000000,1450000000,1000000000000])assert.equal(billionsToVnd(vndToBillions(amount)),amount);
});
test('Detailed information survives validation and remains optional for older records',()=>{
 const details='Nhà hai tầng\nCó sân phía trước.';
 assert.equal(propertySchema.parse({...p,details}).details,details);
 assert.equal(propertySchema.parse(p).details,undefined);
});

import {inPriceRange} from '../src/domain/price-range';
import {generateJSON} from '../src/services/ai/provider';
import {GET as readConfig,POST as writeConfig} from '../src/app/api/ai/config/route';
import {NextRequest} from 'next/server';
test('Price range is inclusive, supports open bounds, and rejects reversed bounds',()=>{
 for(const n of [1e9,1.25e9,1.5e9])assert.equal(inPriceRange(n,1e9,1.5e9),true);
 for(const n of [999999999,1500000001])assert.equal(inPriceRange(n,1e9,1.5e9),false);
 assert.equal(inPriceRange(2e9,1e9,''),true);assert.equal(inPriceRange(5e8,'',1e9),true);assert.equal(inPriceRange(1e9,1.5e9,1e9),false);
});
test('OpenAI and Groq adapters use fixed endpoints and parse JSON',async()=>{
 for(const provider of ['openai','groq'] as const){let seen=false;const fakeFetch:typeof fetch=async(url,init)=>{seen=true;assert.equal(String(url),provider==='openai'?'https://api.openai.com/v1/chat/completions':'https://api.groq.com/openai/v1/chat/completions');const body=JSON.parse(String(init?.body));assert.equal(body.model,'test-model');assert.equal(body.response_format.type,'json_object');assert.equal((init?.headers as Record<string,string>).Authorization,'Bearer dummy-test-key');return new Response(JSON.stringify({choices:[{message:{content:'{"text":"ok"}'}}]}),{status:200})};assert.deepEqual(await generateJSON({provider,model:'test-model',key:'dummy-test-key'},'JSON','hello',fakeFetch),{text:'ok'});assert.equal(seen,true)}
});
test('Provider errors are safe and malformed responses are rejected',async()=>{
 const config={provider:'groq' as const,model:'test-model',key:'dummy-test-key'};
 await assert.rejects(()=>generateJSON(config,'JSON','hello',async()=>new Response('private upstream content',{status:401})),/API key không hợp lệ/);
 await assert.rejects(()=>generateJSON(config,'JSON','hello',async()=>new Response(JSON.stringify({choices:[{message:{content:'not json'}}]}))),/không đúng định dạng/);
});
test('API configuration never returns secrets and is isolated per session',async()=>{
 const make=(body:unknown,cookie='')=>new NextRequest('http://localhost:3000/api/ai/config',{method:'POST',headers:{origin:'http://localhost:3000','content-type':'application/json',cookie},body:JSON.stringify(body)});
 const response=await writeConfig(make({provider:'openai',model:'test-model',key:'dummy-session-key'}));assert.equal(response.status,200);const payload=await response.text();assert.ok(!payload.includes('dummy-session-key'));const cookie=response.headers.get('set-cookie')!.split(';')[0];assert.ok(response.headers.get('set-cookie')!.toLowerCase().includes('httponly'));
 const own=await readConfig(new NextRequest('http://localhost:3000/api/ai/config',{headers:{cookie}}));assert.equal((await own.json()).providers.openai.configured,true);
 const other=await readConfig(new NextRequest('http://localhost:3000/api/ai/config'));assert.equal((await other.json()).providers.openai.configured,false);
 const removed=await writeConfig(make({provider:'openai',remove:true},cookie));assert.equal((await removed.json()).providers.openai.configured,false);
 const blocked=await writeConfig(new NextRequest('http://localhost:3000/api/ai/config',{method:'POST',headers:{origin:'https://other.example','content-type':'application/json'},body:'{}'}));assert.equal(blocked.status,403);
});

import {groqModels} from '../src/services/ai/groq-models';
test('Groq discovery lists chat models and chooses an available default',async()=>{
 const fake:typeof fetch=async(url,init)=>{assert.equal(String(url),'https://api.groq.com/openai/v1/models');assert.equal((init?.headers as Record<string,string>).Authorization,'Bearer dummy-model-key');return new Response(JSON.stringify({data:[{id:'whisper-large-v3'},{id:'llama-3.3-70b-versatile'},{id:'openai/gpt-oss-20b'},{id:'openai/gpt-oss-safeguard-20b'},{id:'retired',active:false}]}))};
 assert.deepEqual(await groqModels('dummy-model-key',fake),['openai/gpt-oss-20b','llama-3.3-70b-versatile']);
 await assert.rejects(()=>groqModels('dummy-model-key',async()=>new Response('',{status:401})),/Groq từ chối/);
});
test('Groq key alone can discover, verify, and save a model without returning the key',async()=>{
 const oldFetch=globalThis.fetch;const calls:string[]=[];
 globalThis.fetch=async(url)=>{calls.push(String(url));return new Response(JSON.stringify(String(url).endsWith('/models')?{data:[{id:'openai/gpt-oss-20b'}]}:{choices:[{message:{content:'{"text":"Kết nối thành công"}'}}]}))};
 try{const r=await writeConfig(new NextRequest('http://localhost:3000/api/ai/config',{method:'POST',headers:{origin:'http://localhost:3000','content-type':'application/json'},body:JSON.stringify({provider:'groq',key:'dummy-groq-key',test:true})}));assert.equal(r.status,200);const result=await r.json();assert.equal(result.providers.groq.model,'openai/gpt-oss-20b');assert.equal(result.tested,true);assert.ok(!JSON.stringify(result).includes('dummy-groq-key'));assert.equal(calls.length,2)}finally{globalThis.fetch=oldFetch}
});

import {saveCustomerNeeds} from '../src/domain/customer-needs';
test('Customer can be saved with every requirement field blank',()=>{
 const d=demoDatabase();const c={...d.customers[0],id:'new-customer',name:'Khách thử'};const before=d.requirements.length;saveCustomerNeeds(d,c,[{id:'empty-new',customerId:c.id,status:'ACTIVE'}]);assert.ok(d.customers.some(x=>x.id===c.id));assert.equal(d.requirements.length,before);
});
test('Customer needs save optional multi-select fields and exact VND range without erasing other needs',()=>{
 const d=demoDatabase();const c=d.customers[0];const existing=d.requirements[0];saveCustomerNeeds(d,c,[{id:'new-need',customerId:c.id,status:'ACTIVE',propertyTypes:['HOUSE','LAND','WAREHOUSE','AGRICULTURAL_LAND'],directions:['E','SE'],priceMin:1e9,priceMax:1.5e9,wardCommunes:[' Phường Phú Lợi ']}]);assert.ok(d.requirements.some(r=>r.id===existing.id));const r=d.requirements.find(r=>r.id==='new-need')!;assert.equal(r.priceMin,1e9);assert.equal(r.priceMax,1.5e9);assert.deepEqual(r.wardCommunes,['Phường Phú Lợi']);assert.equal(r.propertyTypes?.length,4);
});
test('Reversed customer budget fails before changing customer data',()=>{
 const d=demoDatabase();const before=JSON.stringify(d);assert.throws(()=>saveCustomerNeeds(d,{...d.customers[0],name:'Changed'},[{id:'bad',customerId:d.customers[0].id,status:'ACTIVE',priceMin:2e9,priceMax:1e9}]),/Ngân sách/);assert.equal(JSON.stringify(d),before);
});

import {matchCustomerProperties} from '../src/domain/customer-matching';
test('Customer tab finds the same eligible property/requirement pairs as reverse matching',()=>{
 const d=demoDatabase();const c=d.customers[0];const results=matchCustomerProperties(c.id,d.requirements,d.properties,d.settings.weights);
 for(const property of d.properties){const reverse=d.requirements.filter(r=>r.customerId===c.id).some(r=>{const m=matchProperty(property,r,d.settings.weights);return m.eligible&&m.score>0});assert.equal(results.some(x=>x.property.id===property.id),reverse)}assert.ok(results.length>0);
});
test('Customer matches combine multiple requirements without duplicate products and respect updates',()=>{
 const d=demoDatabase();const c=d.customers[0];const req=d.requirements[0];d.requirements.push({...req,id:'second'});let results=matchCustomerProperties(c.id,d.requirements,d.properties);assert.equal(results.length,1);assert.equal(results[0].matches.length,2);
 d.requirements.forEach(r=>r.priceMax=1);results=matchCustomerProperties(c.id,d.requirements,d.properties);assert.equal(results.length,0);
 assert.equal(matchCustomerProperties('another-customer',d.requirements,d.properties).length,0);
});
test('Paused needs and sold properties do not appear in customer matches',()=>{
 const d=demoDatabase();const c=d.customers[0];assert.equal(matchCustomerProperties(c.id,d.requirements.map(r=>({...r,status:'PAUSED'})),d.properties).length,0);assert.equal(matchCustomerProperties(c.id,d.requirements,d.properties.map(p=>({...p,status:'SOLD'}))).length,0);
});

import {isRecommendedMatch} from '../src/domain/match-recommendation';
test('Recommendation threshold includes 70 percent and preserves hard constraints',()=>{
 assert.equal(isRecommendedMatch({eligible:true,score:69}),false);
 assert.equal(isRecommendedMatch({eligible:true,score:70}),true);
 assert.equal(isRecommendedMatch({eligible:true,score:100}),true);
 assert.equal(isRecommendedMatch({eligible:false,score:100}),false);
 assert.equal(isRecommendedMatch({eligible:true,score:NaN}),false);
});
test('Customer recommendations omit eligible properties below 70 percent',()=>{
 const d=demoDatabase();const r={...d.requirements[0],semanticPreferences:['a preference not in any listing']};
 const weights={...d.settings.weights,semantic:300};const m=matchProperty(d.properties[0],r,weights);assert.equal(m.eligible,true);assert.ok(m.score<70);
 assert.equal(matchCustomerProperties(r.customerId,[r],d.properties,weights).length,0);
});

import {propertyIntakeDraft} from '../src/domain/property-intake';
import {publicURL,isPublicAddress,readableHTML} from '../src/services/intake/public-link';
test('AI draft keeps original source text verbatim and preserves source URL',()=>{
 const source='  Nhà 5 × 20m\nGiá 1,5 tỷ. Sổ đỏ.\nChủ: anh A  ';
 const draft=propertyIntakeDraft({details:'An AI summary',legal:{certificateStatus:'RED_BOOK'}},source,'https://example.com/post');
 assert.equal(draft.details,source);assert.equal(draft.sourceUrl,'https://example.com/post');assert.equal(draft.legal.certificateStatus,'RED_BOOK');assert.deepEqual(draft.media.images,[]);assert.equal(draft.status,'');
 assert.equal(propertyIntakeDraft({details:'Nội dung OCR'},'').details,'Nội dung OCR');assert.equal(propertyIntakeDraft({},'tin chưa rõ pháp lý').legal.certificateStatus,undefined);
});
test('Legal certificate choices are optional and survive validation',()=>{
 for(const certificateStatus of ['RED_BOOK','NO_CERTIFICATE'] as const)assert.equal(propertySchema.parse({...p,legal:{certificateStatus,note:'Ghi chú cũ'}}).legal?.certificateStatus,certificateStatus);
 assert.equal(propertySchema.parse(p).legal?.certificateStatus,undefined);assert.equal(propertySchema.safeParse({...p,legal:{certificateStatus:'guessed'}}).success,false);
});
test('Public link intake rejects internal destinations and unsafe schemes',()=>{
 for(const address of ['127.0.0.1','10.1.2.3','172.16.0.1','192.168.1.1','169.254.169.254','100.64.1.1','::1','::ffff:127.0.0.1','fc00::1','fe80::1'])assert.equal(isPublicAddress(address),false);
 assert.equal(isPublicAddress('8.8.8.8'),true);assert.equal(isPublicAddress('2606:4700:4700::1111'),true);
 for(const url of ['http://localhost/a','http://127.1','http://2130706433','http://[::1]/','file:///secret','ftp://example.com','http://user:password@example.com','http://example.com:3000/'])assert.throws(()=>publicURL(url));
 assert.equal(publicURL('https://example.com/post#title').href,'https://example.com/post');
});
test('Link extraction keeps readable listing content and removes scripts',()=>{
 const parsed=readableHTML('<html><head><title>Nhà &amp; đất</title></head><body><nav>Menu</nav><main><p>Bán nhà 5x20.</p><p>Giá 1,5 tỷ.</p><script>secretScript()</script></main><footer>Footer</footer></body></html>');
 assert.equal(parsed.title,'Nhà & đất');assert.ok(parsed.text.includes('Bán nhà 5x20.'));assert.ok(parsed.text.includes('Giá 1,5 tỷ.'));assert.ok(!parsed.text.includes('secretScript'));assert.ok(!parsed.text.includes('Footer'));
});
import {recordCare,pendingCustomers,contactLinks,customerLink} from '../src/domain/customer-care';
test('Care records history and schedules a linked follow-up without completing unrelated tasks',()=>{
 const d=demoDatabase();const c=d.customers[0];const property=d.properties[0];const before=d.tasks.length;
 recordCare(d,{customerId:c.id,propertyId:property.id,type:'ZALO',note:'Khách muốn xem nhà',nextAt:'2030-01-02T09:00:00.000Z'},'2030-01-01T09:00:00.000Z');
 assert.equal(d.tasks.length,before+2);const next=d.tasks[0];const done=d.tasks[1];
 assert.equal(next.status,'TODO');assert.equal(next.type,'FOLLOW_UP');assert.equal(next.customerId,c.id);assert.equal(next.propertyId,property.id);
 assert.equal(done.status,'DONE');assert.equal(done.completedAt,'2030-01-01T09:00:00.000Z');assert.equal(done.note,'Khách muốn xem nhà');
 recordCare(d,{customerId:c.id,type:'CALL',note:'Đã xác nhận lịch',completeTaskId:next.id},'2030-01-02T09:00:00.000Z');
 assert.equal(d.tasks.length,before+2);assert.equal(next.status,'DONE');assert.ok(next.note?.includes('Đã xác nhận lịch'));
 const saved=JSON.stringify(d);assert.throws(()=>recordCare(d,{customerId:c.id,type:'CALL',note:'x',nextAt:'2020-01-01'},'2030-01-01'));
 assert.equal(JSON.stringify(d),saved);assert.throws(()=>recordCare(d,{customerId:c.id,type:'CALL',note:'x',completeTaskId:next.id}));assert.equal(JSON.stringify(d),saved);
});
test('Pending customers include searching without tasks and overdue care, exclude paused/closed',()=>{
 const d=demoDatabase();const base=d.customers[0];d.customers=[{...base,id:'search',status:'Đang tìm'},{...base,id:'late',status:'Đã tư vấn'},{...base,id:'paused',status:'Tạm dừng'},{...base,id:'closed',status:'Đã giao dịch'}];d.requirements=[];
 d.tasks=['late','paused','closed'].map(id=>({id,customerId:id,title:'Care',status:'TODO' as const,type:'CALL' as const,priority:'NORMAL' as const,dueAt:'2030-01-01'}));
 assert.deepEqual(pendingCustomers(d,Date.parse('2030-01-02')).map(x=>x.customer.id),['late','search']);
 d.tasks[0].status='DONE';assert.deepEqual(pendingCustomers(d).map(x=>x.customer.id),['search']);
});
test('Contact links accept phone and Zalo only and encode customer deep links',()=>{
 const c=demoDatabase().customers[0];assert.equal(contactLinks({...c,phone:'090 123 4567',zalo:''}).zalo,'https://zalo.me/0901234567');
 assert.equal(contactLinks({...c,zalo:'javascript:alert(1)'}).zalo,'');assert.equal(contactLinks({...c,zalo:'https://zalo.me.evil.test/x'}).zalo,'');
 assert.equal(customerLink('a&b'),'#customers?customer=a%26b');
});
