import {MATCH_RECOMMENDATION_THRESHOLD} from '@/config';
export function isRecommendedMatch(match:{eligible:boolean;score:number}) {
 return match.eligible && Number.isFinite(match.score) && match.score >= MATCH_RECOMMENDATION_THRESHOLD;
}
