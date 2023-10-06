// License: LGPL-3.0-or-later
import {map as Rmap, split as Rsplit, trim as Rtrim} from 'ramda';
import { CustomFieldDescription, defaultCustomFieldDescription } from '.';

export function parseCustomField(f:string) :CustomFieldDescription {
  const [name, label] = Rmap(Rtrim, Rsplit(':', f))
  return {type: 'supporter', name, label: label || name}
}