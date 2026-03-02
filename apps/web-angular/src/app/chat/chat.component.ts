
export class ChatComponent{
 messages:any[]=[];
 async send(){
   const es=new EventSource('http://localhost:3000/stream');
   es.onmessage=(e)=>{
     this.messages.push(e.data);
   };
 }
}
