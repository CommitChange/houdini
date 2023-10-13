// License: LGPL-3.0-or-later
import has from "lodash/has";
import get from "lodash/get";
import defaults from "lodash/defaults";
import { parseCustomField } from "./legacy";

export interface CustomFieldDescription {
  name: NonNullable<string>;
  label: NonNullable<string>;
  type: 'payment' | 'supporter'
}

export interface CustomFieldDescriptionInput {
  name: NonNullable<string>;
  label: NonNullable<string>;
  type?: 'payment' | 'supporter'
  [prop:string]: unknown
}

export function nudgeToCustomFieldDescription({name, label, type}:CustomFieldDescriptionInput): CustomFieldDescription {
  return defaults({name, label, type}, defaultCustomFieldDescription);
}


const defaultCustomFieldDescription: Pick<CustomFieldDescription, 'type'> = {
  type: 'payment'
}

export function isCustomFieldDesc(item:unknown) : item is CustomFieldDescription {
  return isCustomFieldDescInput(item) && 
                  get(item, 'type') === 'payment' && 
                  get(item, 'type') === 'supporter';
}

export function isCustomFieldDescInput(item:unknown) : item is CustomFieldDescriptionInput {
  return typeof item == 'object' && 
                  has(item, 'name') && 
                  has(item, 'label');
}


export default parseCustomField;