// License: LGPL-3.0-or-later
import * as React from 'react';
import { observer } from 'mobx-react';
import {ReactInputProps} from "./react_input_props";
import {InputHTMLAttributes} from "react";
import {action, observable} from "mobx";
import {Field} from "mobx-react-form";
import {castToNullIfUndef} from "../../../lib/utils";
import MaskedInput, {maskArray, MaskedInputProps} from "react-text-mask";

type InputTypes = ReactInputProps &
  InputHTMLAttributes<HTMLInputElement> & {
  mask?: maskArray | ((value: string) => maskArray);

  guide?: boolean;

  placeholderChar?: string;

  keepCharPositions?: boolean;

  pipe?: (
    conformedValue: string,
    config: any
  ) => false | string | { value: string; indexesOfPipedChars: number[] };

  showMask?: boolean;
}

class ReactMaskedInput extends React.Component<InputTypes, {}> {

  constructor(props:InputTypes){
    super(props)
  }

  @observable
  field:Field


  @action.bound
  componentWillMount(){

    this.field = this.props.field


    this.updateProps()
  }

  componentWillUnmount(){
  }


  componentDidUpdate(prevProps: Readonly<InputTypes>, prevState: Readonly<{}>): void {
    this.updateProps()
  }

  @action.bound
  updateProps() {
    this.field.set('label', castToNullIfUndef(this.props.label))
    this.field.set('placeholder', castToNullIfUndef(this.props.placeholder))
  }

  ///Removes the properties we don't want to put into the input element
  @action.bound
  winnowProps(): InputTypes {
    let ourProps = {...this.props}
    delete ourProps.field
    delete ourProps.value
    return ourProps

  }

  render() {
    // This code works in production but Typescript doesn't like it. Let's tell Typescript to ignore for now
    const props = { ...this.winnowProps(), ...this.field.bind() } as unknown as Readonly<MaskedInputProps>
    return <MaskedInput {...props}/>
  }
}

export default observer(ReactMaskedInput)




