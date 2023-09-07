// License: LGPL-3.0-or-later
import R from 'ramda';
import { CustomFieldDescription } from '.';

export function parseCustomField(f:string) :CustomFieldDescription {
  const [name, label] = R.map(R.trim, R.split(':', f))
  return {name, label: label ? label : name}
}