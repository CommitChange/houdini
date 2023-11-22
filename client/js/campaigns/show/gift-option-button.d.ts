// License: LGPL-3.0-or-later
import h from 'snabbdom/h';

interface GiftOptionButtonState {
  timeRemaining$: () => number;
  clickOption$: (input:[Gift, number, 'one-time'|'recurring']) => void
}

interface Gift {
  amount_one_time?:number;
  amount_recurring?:number;
  name:string;
}

declare function giftOptionButton(state:GiftOptionButtonState,gift:Gift):ReturnType<typeof h>


export default giftOptionButton;




