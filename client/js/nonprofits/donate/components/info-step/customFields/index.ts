// License: LGPL-3.0-or-later
import { CustomFieldDescription } from "../../../parseFields"
import {map as Rmap} from 'ramda';
import { customField } from "./customField";

const h = require('snabbdom/h')


export default function customFields(fields?:CustomFieldDescription[]): ReturnType<typeof h> | '' {
  if(!fields) return ''
  return h('div', Rmap(customField, fields));
}