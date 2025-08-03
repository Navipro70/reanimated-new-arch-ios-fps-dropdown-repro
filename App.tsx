import { useRef, useState } from 'react';
import { Animated, Easing as AnimatedEasing, Button, Dimensions, StyleSheet, View } from 'react-native';

import Reanimated, { Easing, useSharedValue, withTiming } from 'react-native-reanimated';

import ExpandableViewNativeComponent from './specs/ExpandableViewNativeComponent';

const SCREEN_WIDTH = Dimensions.get('window').width;  
const VIEW_HEIGHT = 500;

export default function App() {
  const [isVisible, setIsVisible] = useState(false);
  const [mode, setMode] = useState<'native' | 'reanimated' | 'animated'>('native');

  const translateY = useSharedValue(0);
  const animatedTranslateY = useRef(new Animated.Value(0)).current;

  const handleToggle = () => {
    setIsVisible((prev) => {
      const newValue = !prev;

      if (mode === 'reanimated') {
        if (newValue) {
          translateY.value = withTiming(VIEW_HEIGHT, {
            duration: 320,
            easing: Easing.bezier(0.22, 1, 0.36, 1),
          });
        } else {
          translateY.value = withTiming(0, {
            duration: 260,
            easing: Easing.bezier(0.4, 0.0, 0.6, 1),
          });
        }
      } else if (mode === 'animated') {
        if (newValue) {
          Animated.timing(animatedTranslateY, {
            duration: 320,
            easing: AnimatedEasing.bezier(0.22, 1, 0.36, 1),
            toValue: VIEW_HEIGHT,
            useNativeDriver: true,
          }).start();
        } else {
          Animated.timing(animatedTranslateY, {
            duration: 260,
            easing: AnimatedEasing.bezier(0.4, 0.0, 0.6, 1),
            toValue: 0,
            useNativeDriver: true,
          }).start();
        }
      }

      return newValue;
    });
  };

  return (
    <>
      <View style={styles.container}>
        <Button title={isVisible ? 'Hide' : 'Show'} onPress={handleToggle} />

        <View style={styles.separator} />

        <Button
          title={`Variation: ${mode}`}
          onPress={() => {
            if (mode === 'native') {
              setMode('reanimated');
            } else if (mode === 'reanimated') {
              setMode('animated');
            } else {
              setMode('native');
            }
          }}
        />

        {mode === 'native' && (
          <ExpandableViewNativeComponent
            closeBezier={[0.4, 0.0, 0.6, 1]}
            closeDuration={260}
            isOpen={isVisible}
            openBezier={[0.22, 1, 0.36, 1]}
            openDuration={320}
            style={styles.modal}
          />
        )}
        {mode === 'reanimated' && (
          <Reanimated.View style={[styles.modal, { transform: [{ translateY }] }]} />
        )}
        {mode === 'animated' && (
          <Animated.View
            style={[styles.modal, { transform: [{ translateY: animatedTranslateY }] }]}
          />
        )}
      </View>
    </>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: 'black',
    flex: 1,
    paddingTop: 76,
    position: 'relative',
  },
  modal: {
    backgroundColor: 'white',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    bottom: 0,
    height: VIEW_HEIGHT,
    position: 'absolute',
    width: SCREEN_WIDTH,
  },
  separator: {
    height: 16,
  },
});
