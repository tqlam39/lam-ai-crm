import {isRecommendedMatch} from '@/domain/match-recommendation';
import {Property,Requirement} from './models';
import {matchProperty} from './engines';
import {defaultSettings} from '@/config';
export function matchCustomerProperties(customerId:string,requirements:Requirement[],properties:Property[],weights:Record<string,number>=defaultSettings.weights){
 const needs=requirements.filter(r=>r.customerId===customerId&&r.status==='ACTIVE');
 return properties.flatMap(property=>{
  const matches=needs.map(requirement=>({requirement,...matchProperty(property,requirement,weights)})).filter(m=>isRecommendedMatch(m)).sort((a,b)=>b.score-a.score);
  return matches.length?[{property,score:matches[0].score,reasons:matches[0].reasons,matches}]:[];
 }).sort((a,b)=>b.score-a.score||a.property.code.localeCompare(b.property.code));
}

