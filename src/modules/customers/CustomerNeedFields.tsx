'use client';
import {Requirement} from '@/domain/models';
import {propertyTypes,directions} from '@/config';
import {PriceInput} from '@/components/forms/PriceInput';
import {Field} from '@/components/ui';
export function CustomerNeedFields({value,onChange,areas}:{value:Requirement;onChange:(value:Requirement)=>void;areas:string[]}){
 function toggle(key:'propertyTypes'|'directions'|'wardCommunes',item:string){const selected=value[key]||[];onChange({...value,[key]:selected.includes(item)?selected.filter(x=>x!==item):[...selected,item]})}
 return <div className="form-grid">
 <Field label="Tìm loại bất động sản" full><div className="chips">{Object.entries(propertyTypes).map(([id,label])=><button type="button" key={id} aria-pressed={value.propertyTypes?.includes(id)||false} className={'chip '+(value.propertyTypes?.includes(id)?'active':'')} onClick={()=>toggle('propertyTypes',id)}>{label}</button>)}</div></Field>
 <Field label="Hướng mong muốn" full><div className="direction-grid">{Object.entries(directions).map(([id,label])=><button type="button" key={id} aria-pressed={value.directions?.includes(id)||false} className={'chip '+(value.directions?.includes(id)?'active':'')} onClick={()=>toggle('directions',id)}>{label}</button>)}</div></Field>
 <PriceInput label="Khoảng giá từ (tỷ đồng)" amount={value.priceMin??''} onChange={price=>onChange({...value,priceMin:price===''?undefined:price})}/>
 <PriceInput label="Khoảng giá đến (tỷ đồng)" amount={value.priceMax??''} onChange={price=>onChange({...value,priceMax:price===''?undefined:price})}/>
 <div className="chips span-2"><button className="chip" type="button" onClick={()=>onChange({...value,priceMin:1e9,priceMax:1.5e9})}>1 – 1,5 tỷ</button><button className="text-button" type="button" onClick={()=>onChange({...value,priceMin:undefined,priceMax:undefined})}>Bỏ khoảng giá</button></div>
 {value.priceMin!==undefined&&value.priceMax!==undefined&&value.priceMin>value.priceMax&&<p role="alert" className="error span-2">Giá từ không được lớn hơn giá đến.</p>}
 <Field label="Phường / Xã muốn tìm" full><input value={value.wardCommunes?.join(';')||''} placeholder="Có thể bỏ trống; nhiều khu vực ngăn cách bằng dấu ;" onChange={e=>onChange({...value,wardCommunes:e.target.value?e.target.value.split(';'):[]})}/><div className="chips">{areas.map(area=><button type="button" key={area} aria-pressed={value.wardCommunes?.includes(area)||false} className={'chip '+(value.wardCommunes?.includes(area)?'active':'')} onClick={()=>toggle('wardCommunes',area)}>{area}</button>)}</div></Field>
 </div>;
}
