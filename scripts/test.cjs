const ts=require('typescript');const fs=require('fs');const path=require('path');const Module=require('module');
const original=Module._resolveFilename;Module._resolveFilename=function(name,parent,...rest){return original.call(this,name.startsWith('@/')?path.join(__dirname,'../src',name.slice(2)):name,parent,...rest)};
require.extensions['.ts']=function(mod,file){mod._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022,esModuleInterop:true}}).outputText,file)};
require('../tests/android.test.ts');
