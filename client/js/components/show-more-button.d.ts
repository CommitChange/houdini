// License: LGPL-3.0-or-later
import h from 'snabbdom/h';

interface StreamsType {
	nextPageClicks: () => void;
}

export declare function root(moreLoading:boolean|undefined, remaining?:any|undefined): ReturnType<typeof h>;


export const $streams:StreamsType;

