import { z } from 'zod';
z.config(z.locales.vi());
export const propertySchema = z.object({
 id:z.string(), code:z.string(), title:z.string().trim().min(1,'Nhập tiêu đề'),
 type:z.enum(['HOUSE','LAND','AGRICULTURAL_LAND','WAREHOUSE']), transactionType:z.enum(['SALE','RENT']), status:z.enum(['ACTIVE','SOLD','PAUSED']),
 location:z.object({provinceCity:z.string().trim().min(1,'Thiếu tỉnh/thành'),wardCommune:z.string().trim().min(1,'Thiếu khu vực'),addressText:z.string().optional(), latitude:z.number().min(-90).max(90).optional(),longitude:z.number().min(-180).max(180).optional(),mapUrl:z.string().optional()}),
 dimensions:z.object({width:z.number().positive('Ngang phải lớn hơn 0'),length:z.number().positive('Dài phải lớn hơn 0'),calculatedArea:z.number().optional()}),
 direction:z.enum(['E','S','W','N','NW','SW','NE','SE'],{error:'Chọn hướng'}), bedrooms:z.number().int().min(0,'Nhập số phòng ngủ'),
 price:z.object({amount:z.number().positive('Giá phải lớn hơn 0'),unit:z.literal('VND'),pricePerM2:z.number().optional()}),
 owner:z.object({name:z.string().trim().min(1,'Nhập chủ sở hữu'),phone:z.string().optional()}),
 media:z.object({images:z.array(z.object({id:z.string(),url:z.string().min(1),order:z.number(),createdAt:z.string()})).min(1,'Cần ít nhất 1 ảnh'),videoUrl:z.string().optional()}),
 legal:z.object({certificateStatus:z.enum(['RED_BOOK','NO_CERTIFICATE']).optional(),note:z.string().optional()}).optional(), road:z.object({carAccess:z.boolean().optional()}).optional(),
 details:z.string().optional(), note:z.string().optional(), sourceUrl:z.string().optional(),tags:z.array(z.string()).optional(),
 soldInfo:z.object({soldAt:z.string().min(1),actualSoldPrice:z.number().positive(),note:z.string().optional()}).optional(),
 createdAt:z.string(),updatedAt:z.string(),lastVerifiedAt:z.string().optional()
}).superRefine((p,c)=>{if(p.status==='SOLD'&&!p.soldInfo)c.addIssue({code:'custom',message:'Nhập thông tin giao dịch đã bán',path:['soldInfo']}); if(['LAND','AGRICULTURAL_LAND'].includes(p.type)&&p.bedrooms!==0)c.addIssue({code:'custom',message:'Đất có số phòng ngủ bằng 0',path:['bedrooms']});});
export type Property=z.infer<typeof propertySchema>;
export type PropertyDraft=Record<string,unknown> & {id:string; title?:string};
export interface Customer {id:string;name:string;phone?:string;zalo?:string;facebook?:string;source?:string;status:string;priority:'NORMAL'|'HIGH'|'URGENT';note?:string;createdAt:string;updatedAt:string}
export interface Requirement {id:string;customerId:string;transactionType?:'SALE'|'RENT';propertyTypes?:string[];provinceCities?:string[];wardCommunes?:string[];priceMin?:number;priceMax?:number;widthMin?:number;lengthMin?:number;areaMin?:number;areaMax?:number;directions?:string[];bedroomsMin?:number;carAccess?:boolean;legalPreferences?:string[];semanticPreferences?:string[];rawRequirementText?:string;urgency?:string;status:'ACTIVE'|'PAUSED'|'FULFILLED'}
export interface Task {completedAt?:string;id:string;title:string;type:'CALL'|'ZALO'|'VIEWING'|'SEND_PROPERTY'|'LEGAL'|'FOLLOW_UP'|'OTHER';customerId?:string;propertyId?:string;dueAt?:string;priority:'NORMAL'|'HIGH'|'URGENT';status:'TODO'|'DONE'|'CANCELLED';note?:string}
export interface Activity {id:string;entityId:string;action:string;at:string}
export interface Settings {brand:string;phone:string;favoriteAreas:string[];weights:Record<string,number>}
export interface Database {properties:Property[];drafts:PropertyDraft[];customers:Customer[];requirements:Requirement[];tasks:Task[];activities:Activity[];settings:Settings}
export const customerSchema=z.object({name:z.string().trim().min(1,'Nhập tên khách'),phone:z.string().optional()});
export const requirementSchema=z.object({customerId:z.string().min(1,'Chọn khách'),priceMin:z.number().nonnegative().optional(),priceMax:z.number().positive().optional()}).refine(r=>r.priceMin===undefined||r.priceMax===undefined||r.priceMin<=r.priceMax,'Ngân sách tối thiểu không được lớn hơn tối đa');
export const taskSchema=z.object({title:z.string().trim().min(1,'Nhập nội dung công việc')});



