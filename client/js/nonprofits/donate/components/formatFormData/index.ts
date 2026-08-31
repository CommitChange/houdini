import serialize from "form-serialize"
import {evolve as Revolve, toPairs as RtoPairs} from 'ramda';


interface SerializedFormData {
  customFields?:Record<string, string>; 
  [prop:string]: any;
}

export function formatFormData(data: SerializedFormData) {
  return {
    supporter: Revolve({customFields: RtoPairs}, data)
  }
}


function serializeFormData(form:HTMLFormElement): SerializedFormData {
  return serialize(form, {hash: true})
}