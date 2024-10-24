// License: LGPL-3.0-or-later
export {default as parseCustomField, CustomFieldDescription} from "./customField";
export {default as parseCustomFields} from "./customFields";

export function splitParam(param:string) : string[] {
  return param.split(/[_;,]/);
}