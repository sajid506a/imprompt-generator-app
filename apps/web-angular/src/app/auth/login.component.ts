
export class LoginComponent{
 email='';
 async login(){
  const res=await fetch('http://localhost:3000/login',{
   method:'POST',
   headers:{'Content-Type':'application/json'},
   body:JSON.stringify({email:this.email})
  });
  console.log(await res.json());
 }
}
