import http from 'node:http';
import next from 'next';
const app=next({dev:process.env.NODE_ENV!=='production',hostname:'0.0.0.0',port:3000});
await app.prepare();
http.createServer(app.getRequestHandler()).listen(3000,'0.0.0.0',()=>console.log('LẮM CRM ready at http://localhost:3000'));
