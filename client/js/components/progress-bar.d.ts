// License: LGPL-3.0-or-later
import h from 'snabbdom/h';

interface ProgressBarViewState {
  hidden?:boolean|undefined;
  percentage:number;
  status:string;
}

declare function progressBar(state:ProgressBarViewState): ReturnType< typeof h>;

export default progressBar;

