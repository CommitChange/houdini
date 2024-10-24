// License: LGPL-3.0-or-later
import h from 'virtual-dom/h';

declare function radioAndLabelWrapper(id:string, 
		name: string, 
		customAttributes:any|undefined, 
		content:string, 
		stream:() => void): ReturnType<typeof h>

export default radioAndLabelWrapper;
