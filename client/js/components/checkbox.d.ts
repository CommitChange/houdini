// License: LGPL-3.0-or-later
import h from 'snabbdom/h';

interface CheckboxInput {
  value:any;
  name:string;
  label?:string|undefined;
}

declare function checkbox(obj:CheckboxInput): ReturnType< typeof h>;


export default checkbox;

