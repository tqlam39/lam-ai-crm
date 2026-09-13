// Serial build fallback for restricted Windows environments that cannot spawn workers.
// Standard environments should use `npm run build`.
const path=require.resolve('next/dist/lib/worker');
const original=require(path);
class SerialWorker {
 constructor(file,options){for(const method of options.exposedMethods||[]){this[method]=async(...args)=>require(file)[method](...args)}}
 async end(){} close(){}
}
require.cache[path].exports={...original,Worker:SerialWorker};
require('next/dist/build').default(process.cwd()).then(()=>process.exit(0)).catch(e=>{console.error(e);process.exitCode=1});

