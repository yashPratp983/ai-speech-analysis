import 'dart:async';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

typedef AudioDataCallback = void Function(List<int> audioData);
typedef ErrorCallback = void Function(String error);
typedef InitializedCallback = void Function();

class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  bool _isInitialized = false; // Indicates if the service is initialized
  AudioDataCallback? _onAudioData; // Callback for audio data
  ErrorCallback? _onError; // Callback for errors
  InitializedCallback? _onInitialized; // Callback for initialization

  bool get isInitialized => _isInitialized;

  // Initializes the web audio service
  Future<bool> initialize({
    required AudioDataCallback onAudioData,
    required ErrorCallback onError,
    required InitializedCallback onInitialized,
  }) async {
    if (_isInitialized) return true;

    _onAudioData = onAudioData;
    _onError = onError;
    _onInitialized = onInitialized;

    _setupJavaScriptCallbacks();
    _injectWebAudioScript();

    return true;
  }

  // Sets up JavaScript callbacks for audio processing
  void _setupJavaScriptCallbacks() {
    js.context['dartAudioProcessor'] = js.JsObject.jsify({
      'onAudioData': (js.JsArray audioData) {
        final List<int> samples = [];
        for (int i = 0; i < audioData.length; i++) {
          samples.add(audioData[i] as int);
        }
        _onAudioData?.call(samples);
      },
      'onError': (String error) => _onError?.call('Audio Error: $error'),
      'onInitialized': () {
        _isInitialized = true;
        _onInitialized?.call();
      },
    });
  }

  // Injects the web audio script into the JavaScript context
  void _injectWebAudioScript() {
    js.context.callMethod('eval', [_getWebAudioScript()]);
  }

  // Returns the JavaScript code for the web audio recorder
  String _getWebAudioScript() {
    return '''
      window.realtimeAudioRecorder = {
        audioContext: null,
        mediaRecorder: null,
        source: null,
        processor: null,
        stream: null,
        isRecording: false,
        
        async initialize() {
          try {
            this.stream = await navigator.mediaDevices.getUserMedia({ 
              audio: {
                sampleRate: 44100,
                channelCount: 1,
                echoCancellation: true,
                noiseSuppression: true,
                autoGainControl: true
              } 
            });
            
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)({
              sampleRate: 44100
            });
            
            this.source = this.audioContext.createMediaStreamSource(this.stream);
            this.processor = this.audioContext.createScriptProcessor(4096, 1, 1);
            
            this.source.connect(this.processor);
            this.processor.connect(this.audioContext.destination);
            
            this.processor.onaudioprocess = (event) => {
              if (!this.isRecording) return;
              
              const inputBuffer = event.inputBuffer;
              const inputData = inputBuffer.getChannelData(0);
              
              const int16Array = new Int16Array(inputData.length);
              for (let i = 0; i < inputData.length; i++) {
                const sample = Math.max(-1, Math.min(1, inputData[i]));
                int16Array[i] = sample < 0 ? sample * 0x8000 : sample * 0x7FFF;
              }
              
              dartAudioProcessor.onAudioData(Array.from(int16Array));
            };
            
            dartAudioProcessor.onInitialized();
            return true;
          } catch (error) {
            dartAudioProcessor.onError('Failed to initialize: ' + error.message);
            return false;
          }
        },
        
        startRecording() {
          if (!this.audioContext || !this.processor) {
            dartAudioProcessor.onError('Audio system not initialized');
            return false;
          }
          
          try {
            if (this.audioContext.state === 'suspended') {
              this.audioContext.resume();
            }
            
            this.isRecording = true;
            return true;
          } catch (error) {
            dartAudioProcessor.onError('Failed to start recording: ' + error.message);
            return false;
          }
        },
        
        stopRecording() {
          try {
            this.isRecording = false;
            return true;
          } catch (error) {
            dartAudioProcessor.onError('Failed to stop recording: ' + error.message);
            return false;
          }
        },
        
        cleanup() {
          try {
            this.isRecording = false;
            
            if (this.processor) {
              this.processor.disconnect();
              this.processor = null;
            }
            
            if (this.source) {
              this.source.disconnect();
              this.source = null;
            }
            
            if (this.stream) {
              this.stream.getTracks().forEach(track => track.stop());
              this.stream = null;
            }
            
            if (this.audioContext && this.audioContext.state !== 'closed') {
              this.audioContext.close();
              this.audioContext = null;
            }
          } catch (error) {
            console.error('Cleanup error:', error);
          }
        }
      };
      
      window.realtimeAudioRecorder.initialize();
    ''';
  }

  // Starts audio recording
  bool startRecording() {
    if (!_isInitialized) return false;

    try {
      final success = js.context['realtimeAudioRecorder'].callMethod(
        'startRecording',
      );
      return success == true;
    } catch (e) {
      _onError?.call('Failed to start recording: $e');
      return false;
    }
  }

  // Stops audio recording
  bool stopRecording() {
    try {
      js.context['realtimeAudioRecorder'].callMethod('stopRecording');
      return true;
    } catch (e) {
      _onError?.call('Failed to stop recording: $e');
      return false;
    }
  }

  // Cleans up audio resources
  void cleanup() {
    try {
      js.context['realtimeAudioRecorder']?.callMethod('cleanup');
      _isInitialized = false;
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }
}
