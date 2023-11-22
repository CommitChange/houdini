// License: LGPL-3.0-or-later
declare function confirmation(msg?:string|undefined, success_cb?:string|undefined):{
	confirmed:() => void;
	denied:() => void;
}

export default confirmation;
