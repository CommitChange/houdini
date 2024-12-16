// License: LGPL-3.0-or-later
import h from 'snabbdom/h';
import type {NotificationState } from 'ff-core/notification';


interface EmailSettings {
  notify_payments:boolean
 notify_campaigns:boolean
 notify_events:boolean
 notify_payouts:boolean
 notify_recurring_donations:boolean
}

export interface EmailSettingsViewState {
  email_settings$: () => (undefined|EmailSettings);
  loading$:() => boolean;
  notification:NotificationState
}

declare function view(state:EmailSettingsViewState): ReturnType<typeof h>;

export default view;
