import { NativeModules, NativeEventEmitter } from 'react-native';
import { useEffect } from 'react';

const RNScreenshotPrevent = NativeModules.RNScreenshotPrevent;

const eventEmitter = new NativeEventEmitter(RNScreenshotPrevent);
/**
 * subscribes to userDidTakeScreenshot event
 * @param {function} callback handler
 * @returns {function} unsubscribe fn
 */
const addListen = (fn) => {
	if (typeof fn !== 'function') {
		console.error(
			'RNScreenshotPrevent: addListener requires valid callback function'
		);
		return {
			remove: (): void => {
				console.error(
					'RNScreenshotPrevent: remove not work because addListener requires valid callback function'
				);
			},
		};
	}

	return eventEmitter.addListener('userDidTakeScreenshot', fn);
};

export const usePreventScreenshot = () => {
	useEffect(() => {
		RNScreenshotPrevent.enabled(true);
		return () => {
			RNScreenshotPrevent.enabled(false);
		};
	}, []);
};

export const useDisableSecureView = () => {
	useEffect(() => {
		RNScreenshotPrevent.enableSecureView();
		return () => {
			RNScreenshotPrevent.disableSecureView();
		};
	}, []);
};

export const addListener = addListen;
export default RNScreenshotPrevent;
