// License: LGPL-3.0-or-later
import dedication_form, { DedicationData } from "./components/info-step/dedication_form"
const h = require('snabbdom/h');

declare const I18n:  {t:(...rest:string[]) => string};
// A contact info form for a donor to add a dedication in honor/memory of somebody
interface DedicationFormState  {
  dedicationData$: () => (DedicationData | null)
  submitDedication$: (target:EventTarget) => void;

}

export function view(state:DedicationFormState) : ReturnType<typeof h>{

  const dedicationData = state.dedicationData$() || {}

  const submitDedication = state.submitDedication$;

  return dedication_form({dedicationData, submitDedication, I18n});
  
};
