import type { HostComponent, ViewProps } from 'react-native';

import { Double, Int32 } from 'react-native/Libraries/Types/CodegenTypes';
import codegenNativeCommands from 'react-native/Libraries/Utilities/codegenNativeCommands';
import codegenNativeComponent from 'react-native/Libraries/Utilities/codegenNativeComponent';

export interface NativeProps extends ViewProps {
  closeBezier?: ReadonlyArray<Double>;
  closeDuration?: Int32;

  isOpen?: boolean;
  openBezier?: ReadonlyArray<Double>;

  openDuration?: Int32;
  title?: string;
}

export default codegenNativeComponent<NativeProps>(
  'CustomExpandableView',
) as HostComponent<NativeProps>;

export interface CustomExpandableViewCommands {
  close: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  open: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
  toggle: (viewRef: React.ElementRef<HostComponent<NativeProps>>) => void;
}

export const Commands = codegenNativeCommands<CustomExpandableViewCommands>({
  supportedCommands: ['toggle', 'open', 'close'],
});
