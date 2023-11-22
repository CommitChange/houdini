// License: LGPL-3.0-or-later
import h from 'snabbdom/h'

declare module 'ff-core/notification' {
  export interface NotificationInitState {
    hideDelay?: number |undefined;
    message$?: (() => (string|undefined)) | undefined
  
  }
  
  export interface NotificationState {
    hideDelay: number;
    message$: () => (string|undefined);
    msg$: () => (string|undefined);
  }
  
  function init(state:NotificationInitState) : NotificationState;
  function view(state:NotificationState): ReturnType<typeof h>;
}


