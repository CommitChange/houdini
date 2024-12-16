// License: LGPL-3.0-or-later
import h from 'snabbdom/h';


interface ColorPickerViewState {
  color$: () => string
}

export declare function init(defaultColor:string): ColorPickerViewState;

export declare function view(state:ColorPickerViewState): ReturnType< typeof h>