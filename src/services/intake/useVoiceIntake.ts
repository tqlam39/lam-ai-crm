import {NativeCRM,isAndroid} from '@/native/bridge';
'use client';
import {useEffect,useRef,useState} from 'react';
export function useVoiceIntake(onText:(value:string)=>void,onError:(message:string)=>void){
 const [listening,setListening]=useState(false);const [interim,setInterim]=useState('');const active=useRef<any>(null);const append=useRef(onText);append.current=onText;const report=useRef(onError);report.current=onError;
 useEffect(()=>()=>{active.current?.abort();active.current=null},[]);
 function toggle(){if(isAndroid){if(listening)return;setListening(true);NativeCRM.recognizeSpeech().then((r:any)=>{if(r.text)append.current(r.text)}).catch((e:Error)=>report.current(e.message)).finally(()=>setListening(false));return}if(active.current){active.current.stop();return}const API=(window as any).SpeechRecognition||(window as any).webkitSpeechRecognition;
 if(!API){report.current('Trình duyệt chưa hỗ trợ nhận giọng nói. Chạm ô nội dung rồi dùng micro trên bàn phím iPhone, hoặc mở bằng Chrome/Safari có hỗ trợ.');return}
 const speech=new API();speech.lang='vi-VN';speech.continuous=true;speech.interimResults=true;active.current=speech;
 speech.onresult=(event:any)=>{let partial='';for(let i=event.resultIndex;i<event.results.length;i++){if(event.results[i].isFinal)append.current(event.results[i][0].transcript);else partial+=event.results[i][0].transcript}setInterim(partial)};
 speech.onerror=(event:any)=>{if(event.error!=='aborted')report.current(event.error==='not-allowed'?'Chưa có quyền micro. Cho phép micro trong trình duyệt để nhập bằng giọng nói.':'Không nhận được giọng nói. Kiểm tra mạng và micro, sau đó thử lại.');speech.abort()};
 speech.onend=()=>{if(active.current===speech){active.current=null;setListening(false);setInterim('')}};
 try{speech.start();setListening(true)}catch{active.current=null;setListening(false);report.current('Không mở được micro. Vui lòng thử lại.')}
 }
 return {listening,interim,toggle};
}
