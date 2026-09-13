export function inPriceRange(amount:number,min:number|'',max:number|'') {
 return (min===''||amount>=min)&&(max===''||amount<=max)&&(min===''||max===''||min<=max);
}
