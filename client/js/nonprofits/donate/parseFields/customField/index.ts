// License: LGPL-3.0-or-later
import has from "lodash/has";
import get from "lodash/get";
import { parseCustomField } from "./legacy";

export interface CustomFieldDescription {
  name: NonNullable<string>;
  label: NonNullable<string>;
  type: 'payment' | 'supporter'
}

export const defaultCustomFieldDescription: Pick<CustomFieldDescription, 'type'> = {
  type: 'payment'
}

export function isCustomFieldDesc(item:unknown) : item is CustomFieldDescription {
  return isCustomFieldDescAfterDefaulting(item) && 
                  get(item, 'type') === 'payment' && 
                  get(item, 'type') === 'supporter';
}

export function isCustomFieldDescAfterDefaulting(item:unknown) : item is Omit<CustomFieldDescription, 'type'> {
  return typeof item == 'object' && 
                  has(item, 'name') && 
                  has(item, 'label');
}


export default parseCustomField;