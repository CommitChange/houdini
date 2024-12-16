// License: LGPL-3.0-or-later
import h from 'snabbdom/h';
import type { EmailSettingsViewState } from './view';

declare function init(): EmailSettingsViewState;

/**
 * this is a re-export of view
 * 
 */
declare function view(state:EmailSettingsViewState): ReturnType<typeof h>;
