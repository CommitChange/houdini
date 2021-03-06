// License: LGPL-3.0-or-later
import * as React from 'react';

export interface ScreenReaderOnlyTextProps
{
}

const ScreenReaderOnlyText
  :React.StatelessComponent<ScreenReaderOnlyTextProps> =  (props) => {
    const style:React.CSSProperties = {
      position: 'absolute',
      width: '1px',
      height: '1px',
      padding: 0,
      margin: '-1px',
      overflow: 'hidden',
      clip: 'rect(0,0,0,0)',
      border: 0
    }
    return <span style={style}>{props.children}</span>
}

ScreenReaderOnlyText.displayName = 'ScreenReaderOnlyText'

export default ScreenReaderOnlyText;



