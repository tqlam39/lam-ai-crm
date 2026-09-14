import {Database} from '@/domain/models';import {emptyDatabase} from './demo';import {isAndroid,NativeCRM} from '@/native/bridge';
// Android uses transactional SQLite. Browser preview is separate and never a phone database.
export async function loadLocal():Promise<Database>{const raw=isAndroid?(await NativeCRM.readDatabase()).text:localStorage.getItem('lam-crm-android-preview-v1');return raw?JSON.parse(raw):emptyDatabase()}
export async function saveLocal(data:Database){const text=JSON.stringify(data);if(isAndroid)await NativeCRM.writeDatabase({text});else localStorage.setItem('lam-crm-android-preview-v1',text)}
export async function exportCloud():Promise<Database>{return loadLocal()}
