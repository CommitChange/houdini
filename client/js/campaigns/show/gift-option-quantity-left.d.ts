// License: LGPL-3.0-or-later
import h from 'snabbdom/h';

interface Gift {
  hide_contributions?:boolean|undefined;
  quantity?:number
}

declare function giftOptionQuantityLeft(gift:Gift): ReturnType<typeof h>;

export default giftOptionQuantityLeft;
