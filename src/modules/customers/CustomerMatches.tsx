'use client';
import {useState,useEffect} from 'react';
import {useStore} from '@/services/repository/context';
import {matchCustomerProperties} from '@/domain/customer-matching';
import {PropertyCard,PropertyDetail} from '@/modules/properties';
import {PropertyForm} from '@/modules/properties/form';
import {Property} from '@/domain/models';
export function CustomerMatches({customerId,onAddNeed}:{customerId:string;onAddNeed:()=>void}){
 const {data}=useStore();const [requirementId,setRequirementId]=useState('');const [selectedId,setSelectedId]=useState<string|null>(null);const [editing,setEditing]=useState<Property|null>(null);
 useEffect(()=>{const close=()=>setSelectedId(null);window.addEventListener('hashchange',close);return()=>window.removeEventListener('hashchange',close)},[]);
 const needs=data.requirements.filter(r=>r.customerId===customerId&&r.status==='ACTIVE');
 const results=matchCustomerProperties(customerId,requirementId?needs.filter(r=>r.id===requirementId):needs,data.properties,data.settings.weights);
 const selected=data.properties.find(p=>p.id===selectedId);
 return <section className="customer-matches"><div className="section-heading"><h3>BĐS phù hợp với khách · {results.length}</h3></div>
 {needs.length>1&&<label className="field"><span>So khớp theo nhu cầu</span><select value={requirementId} onChange={e=>setRequirementId(e.target.value)}><option value="">Tất cả nhu cầu đang tìm</option>{needs.map((r,i)=><option key={r.id} value={r.id}>Nhu cầu {i+1}{r.wardCommunes?.length?' · '+r.wardCommunes.join(', '):''}</option>)}</select></label>}
 <p className="muted">Đề xuất từ 70% trở lên, theo nhu cầu đang tìm và xếp điểm từ cao xuống thấp. Một BĐS phù hợp nhiều nhu cầu chỉ hiển thị một lần.</p>
 {!needs.length?<div className="notice">Khách chưa có nhu cầu đang tìm.<br/><button className="text-button" onClick={onAddNeed}>+ Thêm nhu cầu để so khớp</button></div>:!results.length?<div className="notice">Chưa có BĐS đạt ngưỡng đề xuất 70% trong quỹ hàng đã tải. Kiểm tra loại BĐS, giá, hướng và khu vực trong nhu cầu bên dưới. Nếu nhu cầu đang để trống, hãy thêm ít nhất một tiêu chí để chấm điểm.</div>:<div className="customer-match-grid">{results.map(result=><article key={result.property.id}><div className="match-result-head"><b className="match-badge">{result.score}%</b><span className="muted">{result.matches.length} nhu cầu phù hợp</span></div><PropertyCard property={result.property} onSelect={()=>setSelectedId(result.property.id)}/><div className="reasons">{result.reasons.map(reason=><span key={reason}>✓ {reason}</span>)}</div><button className="secondary" onClick={()=>setSelectedId(result.property.id)}>Xem sản phẩm / Chia sẻ</button></article>)}</div>}
 {selected&&<PropertyDetail property={selected} onClose={()=>setSelectedId(null)} onEdit={()=>{setEditing(selected);setSelectedId(null)}}/>}
 {editing&&<PropertyForm initial={editing} onClose={()=>setEditing(null)}/>}
 </section>;
}

