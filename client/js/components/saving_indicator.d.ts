// License: LGPL-3.0-or-later
import h from "virtual-dom/h";

interface SavingIndicatorViewState {
  hide?:boolean|undefined;
  text:string;
}


declare function savingIndicator(savingState:SavingIndicatorViewState): ReturnType<typeof h>;

export default savingIndicator;