// License: LGPL-3.0-or-later
import R from "ramda";
import parseCustomField, { CustomFieldDescription } from "../customField";

export function parseCustomFields(fields:string): CustomFieldDescription[] {
  return R.map(parseCustomField, R.split(',',  fields))
}
