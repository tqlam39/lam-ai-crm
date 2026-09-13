import {Customer,Database,Requirement,customerSchema,requirementSchema} from './models';
export function saveCustomerNeeds(data:Database,customer:Customer,needs:Requirement[]){
 customerSchema.parse(customer);
 const prepared=needs.map(r=>({...r,customerId:customer.id,wardCommunes:r.wardCommunes?.map(x=>x.trim()).filter(Boolean)}));
 prepared.forEach(r=>{const checked=requirementSchema.safeParse(r);if(!checked.success)throw Error(checked.error.issues[0].message)});
 const existing=new Set(data.requirements.map(r=>r.id));
 const meaningful=(r:Requirement)=>existing.has(r.id)||!!(r.propertyTypes?.length||r.directions?.length||r.wardCommunes?.length||r.priceMin!==undefined||r.priceMax!==undefined||r.rawRequirementText?.trim()||r.transactionType||r.widthMin!==undefined||r.lengthMin!==undefined||r.areaMin!==undefined||r.areaMax!==undefined||r.bedroomsMin!==undefined||r.carAccess||r.semanticPreferences?.length||r.legalPreferences?.length||r.provinceCities?.length);
 data.customers=data.customers.filter(c=>c.id!==customer.id);
 data.customers.unshift({...customer,updatedAt:new Date().toISOString()});
 const editedIds=new Set(prepared.map(r=>r.id));data.requirements=[...data.requirements.filter(r=>!editedIds.has(r.id)),...prepared.filter(meaningful)];
}

