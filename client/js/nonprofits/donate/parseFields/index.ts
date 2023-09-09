// License: LGPL-3.0-or-later
import parseCustomField, {CustomFieldDescription} from "./customField";
import parseCustomFields from "./customFields";

export {parseCustomField, parseCustomFields, CustomFieldDescription};


export function splitParam(param:string) : string[] {
  return param.split(/[_;,]/);
}
