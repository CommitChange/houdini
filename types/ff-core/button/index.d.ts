// License: LGPL-3.0-or-later
import h from 'snabbdom/h'

declare module 'ff-core/button';

interface ButtonState {
  loadingText?: string |undefined
  buttonText?:string |undefined;
  error$?: () => string;
  loading$?:  () => string;
}

declare function view(state:ButtonState): ReturnType<typeof h>;

