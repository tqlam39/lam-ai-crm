'use client';
import {useEffect, useState} from 'react';
import {Field} from '@/components/ui';
import {billionsToVnd, vndToBillions} from '@/domain/property-price';
export function PriceInput({amount,onChange,label='Giá (tỷ đồng) *'}:{amount:number|'';onChange:(value:number|'')=>void;label?:string}) {
  const [input,setInput]=useState(()=>vndToBillions(amount));
  useEffect(()=>{setInput(previous=>billionsToVnd(previous)===amount?previous:vndToBillions(amount))},[amount]);
  return <Field label={label}>
    <input type="text" inputMode="decimal" placeholder="Ví dụ: 1,5" value={input} onChange={event=>{
      const next=event.target.value;
      if(!/^\d{0,6}([.,]\d{0,9})?$/.test(next)) return;
      setInput(next);onChange(billionsToVnd(next));
    }}/>
    <small className="muted">{typeof amount==='number'&&amount>0?`${amount.toLocaleString('vi-VN')} VNĐ`:'1,5 tỷ = 1.500.000.000 VNĐ'}</small>
  </Field>;
}
