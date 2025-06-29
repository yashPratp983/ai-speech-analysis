import tempfile
import os
import wave
from typing import Optional, Tuple
import logging
import numpy as np
from scipy import signal
import librosa
from app.services.speech_service import speech_service
from app.core.config.initialiser import initialized_dbs

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class AudioPreprocessor:
    """Enhanced audio preprocessing with robust speech detection.
    
    This class provides methods to preprocess audio files, analyze them for speech presence,
    and enhance audio quality if speech is detected.
    """

    def __init__(self):
        # Speech detection thresholds
        self.MIN_DURATION = 0.2  # Minimum duration in seconds
        self.MIN_RMS_THRESHOLD = 0.002  # Minimum RMS energy
        self.MIN_SPECTRAL_CENTROID = 300  # Hz - human speech typically above this
        self.MAX_SPECTRAL_CENTROID = 4000  # Hz - human speech typically below this
        self.MIN_ACTIVITY_RATIO = 0.15  # Minimum ratio of active frames
        self.ZCR_MIN = 0.02  # Minimum zero crossing rate
        self.ZCR_MAX = 0.25  # Maximum zero crossing rate
        self.SPECTRAL_ROLLOFF_THRESHOLD = 0.85  # Spectral rolloff point

    def preprocess_audio(self, file_path: str) -> Tuple[str, bool, dict]:
        """
        Enhanced audio preprocessing with comprehensive speech detection.
        
        Args:
            file_path (str): Path to the audio file.
            
        Returns:
            Tuple[str, bool, dict]: A tuple containing the processed file path, 
            a boolean indicating if speech is detected, and a dictionary of analysis results.
        """
        try:
            logger.info(f"Starting enhanced audio preprocessing: {file_path}")
            
            # Load audio file
            audio_data, sample_rate = self._load_audio_file(file_path)
            
            if audio_data is None:
                return file_path, False, {"error": "Failed to load audio"}
            
            # Perform comprehensive speech analysis
            analysis_results = self._analyze_audio_for_speech(audio_data, sample_rate)
            
            # Determine if speech is present based on multiple criteria
            has_speech = self._determine_speech_presence(analysis_results)
            
            # If speech is detected, optionally enhance the audio
            processed_file_path = file_path
            if has_speech:
                processed_file_path = self._enhance_audio_quality(
                    audio_data, sample_rate, file_path
                )
            
            logger.info(f"Speech detection result: {has_speech}")
            logger.info(f"Analysis results: {analysis_results}")
            
            return processed_file_path, has_speech, analysis_results
            
        except Exception as e:
            logger.error(f"Audio preprocessing failed: {str(e)}")
            return file_path, True, {"error": str(e)}  # Fallback to assume speech

    def _load_audio_file(self, file_path: str) -> Tuple[Optional[np.ndarray], int]:
        """Load audio file and return normalized audio data and sample rate.
        
        Args:
            file_path (str): Path to the audio file.
            
        Returns:
            Tuple[Optional[np.ndarray], int]: A tuple containing the audio data as a numpy array
            and the sample rate. Returns None and 0 if loading fails.
        """
        try:
            # Try using librosa first (handles more formats)
            try:
                audio_data, sample_rate = librosa.load(file_path, sr=None)
                logger.info(f"Loaded audio with librosa: {len(audio_data)} samples at {sample_rate}Hz")
                return audio_data, sample_rate
            except:
                # Fallback to wave module for WAV files
                with wave.open(file_path, 'rb') as wav_file:
                    frames = wav_file.getnframes()
                    sample_rate = wav_file.getframerate()
                    audio_data = wav_file.readframes(frames)
                    
                    # Convert to numpy array and normalize
                    if wav_file.getsampwidth() == 1:
                        audio_array = np.frombuffer(audio_data, dtype=np.uint8)
                        audio_array = (audio_array - 128) / 128.0
                    elif wav_file.getsampwidth() == 2:
                        audio_array = np.frombuffer(audio_data, dtype=np.int16)
                        audio_array = audio_array / 32768.0
                    else:
                        logger.warning(f"Unsupported bit depth: {wav_file.getsampwidth()}")
                        return None, 0
                    
                    logger.info(f"Loaded audio with wave: {len(audio_array)} samples at {sample_rate}Hz")
                    return audio_array, sample_rate
                    
        except Exception as e:
            logger.error(f"Failed to load audio file: {str(e)}")
            return None, 0

    def _analyze_audio_for_speech(self, audio_data: np.ndarray, sample_rate: int) -> dict:
        """Comprehensive audio analysis for speech detection.
        
        Args:
            audio_data (np.ndarray): The audio data as a numpy array.
            sample_rate (int): The sample rate of the audio data.
            
        Returns:
            dict: A dictionary containing analysis results such as duration, RMS energy,
            zero crossing rate, spectral features, temporal features, and VAD results.
        """
        try:
            duration = len(audio_data) / sample_rate
            
            # Basic energy analysis
            rms_energy = np.sqrt(np.mean(audio_data**2))
            max_amplitude = np.max(np.abs(audio_data))
            
            # Zero crossing rate analysis
            zero_crossings = np.sum(np.diff(np.sign(audio_data)) != 0)
            zcr = zero_crossings / len(audio_data)
            
            # Spectral analysis using librosa
            spectral_features = self._extract_spectral_features(audio_data, sample_rate)
            
            # Temporal analysis
            temporal_features = self._analyze_temporal_characteristics(audio_data, sample_rate)
            
            # Voice activity detection
            vad_results = self._voice_activity_detection(audio_data, sample_rate)
            
            analysis_results = {
                'duration': duration,
                'rms_energy': rms_energy,
                'max_amplitude': max_amplitude,
                'zero_crossing_rate': zcr,
                'spectral_features': spectral_features,
                'temporal_features': temporal_features,
                'vad_results': vad_results
            }
            
            return analysis_results
            
        except Exception as e:
            logger.error(f"Audio analysis failed: {str(e)}")
            return {'error': str(e)}

    def _extract_spectral_features(self, audio_data: np.ndarray, sample_rate: int) -> dict:
        """Extract spectral features relevant to speech detection.
        
        Args:
            audio_data (np.ndarray): The audio data as a numpy array.
            sample_rate (int): The sample rate of the audio data.
            
        Returns:
            dict: A dictionary containing spectral features such as spectral centroid,
            spectral rolloff, spectral bandwidth, MFCC means, and spectral contrast.
        """
        try:
            # Spectral centroid (brightness)
            spectral_centroids = librosa.feature.spectral_centroid(y=audio_data, sr=sample_rate)[0]
            mean_spectral_centroid = np.mean(spectral_centroids)
            
            # Spectral rolloff (frequency below which 85% of energy is contained)
            spectral_rolloff = librosa.feature.spectral_rolloff(y=audio_data, sr=sample_rate)[0]
            mean_spectral_rolloff = np.mean(spectral_rolloff)
            
            # Spectral bandwidth
            spectral_bandwidth = librosa.feature.spectral_bandwidth(y=audio_data, sr=sample_rate)[0]
            mean_spectral_bandwidth = np.mean(spectral_bandwidth)
            
            # MFCC features (first few coefficients)
            mfccs = librosa.feature.mfcc(y=audio_data, sr=sample_rate, n_mfcc=13)
            mfcc_means = np.mean(mfccs, axis=1)
            
            # Spectral contrast
            spectral_contrast = librosa.feature.spectral_contrast(y=audio_data, sr=sample_rate)
            mean_spectral_contrast = np.mean(spectral_contrast, axis=1)
            
            return {
                'spectral_centroid': mean_spectral_centroid,
                'spectral_rolloff': mean_spectral_rolloff,
                'spectral_bandwidth': mean_spectral_bandwidth,
                'mfcc_means': mfcc_means.tolist(),
                'spectral_contrast': mean_spectral_contrast.tolist()
            }
            
        except Exception as e:
            logger.error(f"Spectral feature extraction failed: {str(e)}")
            return {}

    def _analyze_temporal_characteristics(self, audio_data: np.ndarray, sample_rate: int) -> dict:
        """Analyze temporal characteristics of the audio.
        
        Args:
            audio_data (np.ndarray): The audio data as a numpy array.
            sample_rate (int): The sample rate of the audio data.
            
        Returns:
            dict: A dictionary containing temporal features such as activity ratio,
            onset rate, active frames, and total frames.
        """
        try:
            # Frame-based analysis
            frame_length = int(0.025 * sample_rate)  # 25ms frames
            hop_length = int(0.01 * sample_rate)     # 10ms hop
            
            # Calculate energy per frame
            frames = librosa.util.frame(audio_data, frame_length=frame_length, 
                                      hop_length=hop_length, axis=0)
            frame_energies = np.sum(frames**2, axis=0)
            
            # Activity detection based on energy
            energy_threshold = np.percentile(frame_energies, 30)  # Dynamic threshold
            active_frames = frame_energies > energy_threshold
            activity_ratio = np.sum(active_frames) / len(active_frames)
            
            # Onset detection (speech typically has clear onsets)
            onset_frames = librosa.onset.onset_detect(y=audio_data, sr=sample_rate)
            onset_rate = len(onset_frames) / (len(audio_data) / sample_rate)
            
            return {
                'activity_ratio': activity_ratio,
                'onset_rate': onset_rate,
                'active_frames': int(np.sum(active_frames)),
                'total_frames': len(active_frames)
            }
            
        except Exception as e:
            logger.error(f"Temporal analysis failed: {str(e)}")
            return {}

    def _voice_activity_detection(self, audio_data: np.ndarray, sample_rate: int) -> dict:
        """Simple voice activity detection.
        
        Args:
            audio_data (np.ndarray): The audio data as a numpy array.
            sample_rate (int): The sample rate of the audio data.
            
        Returns:
            dict: A dictionary containing VAD results such as voice ratio, voice frames,
            total frames, and energy threshold.
        """
        try:
            # Frame-based VAD
            frame_length = int(0.02 * sample_rate)  # 20ms frames
            hop_length = int(0.01 * sample_rate)    # 10ms hop
            
            frames = librosa.util.frame(audio_data, frame_length=frame_length, 
                                      hop_length=hop_length, axis=0)
            
            # Calculate features for each frame
            frame_energies = np.sum(frames**2, axis=0)
            frame_zcrs = np.array([np.sum(np.diff(np.sign(frame)) != 0) / len(frame) 
                                 for frame in frames.T])
            
            # Adaptive thresholding
            energy_threshold = np.percentile(frame_energies, 35)
            zcr_min, zcr_max = np.percentile(frame_zcrs, [20, 80])
            
            # Voice activity based on energy and ZCR
            voice_frames = (frame_energies > energy_threshold) & \
                          (frame_zcrs > zcr_min) & \
                          (frame_zcrs < zcr_max)
            
            voice_ratio = np.sum(voice_frames) / len(voice_frames)
            
            return {
                'voice_ratio': voice_ratio,
                'voice_frames': int(np.sum(voice_frames)),
                'total_frames': len(voice_frames),
                'energy_threshold': energy_threshold
            }
            
        except Exception as e:
            logger.error(f"VAD failed: {str(e)}")
            return {}

    def _determine_speech_presence(self, analysis_results: dict) -> bool:
        """Determine if speech is present based on multiple criteria.
        
        Args:
            analysis_results (dict): A dictionary containing analysis results.
            
        Returns:
            bool: True if speech is detected, False otherwise.
        """
        try:
            if 'error' in analysis_results:
                return True  # Fallback to assume speech on error
            
            # Check minimum duration
            if analysis_results.get('duration', 0) < self.MIN_DURATION:
                logger.info(f"Audio too short: {analysis_results.get('duration', 0):.2f}s")
                return False
            
            # Check basic energy criteria
            rms_energy = analysis_results.get('rms_energy', 0)
            if rms_energy < self.MIN_RMS_THRESHOLD:
                logger.info(f"RMS energy too low: {rms_energy:.6f}")
                return False
            
            # Check zero crossing rate
            zcr = analysis_results.get('zero_crossing_rate', 0)
            if zcr < self.ZCR_MIN or zcr > self.ZCR_MAX:
                logger.info(f"ZCR out of speech range: {zcr:.4f}")
                # Don't immediately return False, check other criteria
            
            # Check spectral features
            spectral_features = analysis_results.get('spectral_features', {})
            if spectral_features:
                spectral_centroid = spectral_features.get('spectral_centroid', 0)
                if (spectral_centroid < self.MIN_SPECTRAL_CENTROID or 
                    spectral_centroid > self.MAX_SPECTRAL_CENTROID):
                    logger.info(f"Spectral centroid out of speech range: {spectral_centroid:.1f}Hz")
                    # Don't immediately return False, check other criteria
            
            # Check temporal characteristics
            temporal_features = analysis_results.get('temporal_features', {})
            activity_ratio = temporal_features.get('activity_ratio', 0)
            if activity_ratio < self.MIN_ACTIVITY_RATIO:
                logger.info(f"Activity ratio too low: {activity_ratio:.3f}")
                return False
            
            # Check VAD results
            vad_results = analysis_results.get('vad_results', {})
            voice_ratio = vad_results.get('voice_ratio', 0)
            if voice_ratio < 0.1:  # Less than 10% voice activity
                logger.info(f"Voice ratio too low: {voice_ratio:.3f}")
                return False
            
            # If we've passed all checks, likely contains speech
            logger.info("Speech presence confirmed by multiple criteria")
            return True
            
        except Exception as e:
            logger.error(f"Speech determination failed: {str(e)}")
            return True  # Fallback to assume speech

    def _enhance_audio_quality(self, audio_data: np.ndarray, sample_rate: int, 
                             original_file_path: str) -> str:
        """Enhance audio quality when speech is detected.
        
        Args:
            audio_data (np.ndarray): The audio data as a numpy array.
            sample_rate (int): The sample rate of the audio data.
            original_file_path (str): The original file path of the audio.
            
        Returns:
            str: The file path of the enhanced audio.
        """
        try:
            # Simple noise reduction and normalization
            enhanced_audio = audio_data.copy()
            
            # Normalize audio
            if np.max(np.abs(enhanced_audio)) > 0:
                enhanced_audio = enhanced_audio / np.max(np.abs(enhanced_audio)) * 0.95
            
            # Simple high-pass filtering to remove low-frequency noise
            nyquist = sample_rate / 2
            high_cutoff = 80  # Hz
            if high_cutoff < nyquist:
                sos = signal.butter(4, high_cutoff / nyquist, btype='high', output='sos')
                enhanced_audio = signal.sosfilt(sos, enhanced_audio)
            
            # Save enhanced audio to temporary file
            with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_file:
                temp_file_path = temp_file.name
                
            # Convert back to int16 for saving
            enhanced_audio_int16 = (enhanced_audio * 32767).astype(np.int16)
            
            with wave.open(temp_file_path, 'wb') as wav_file:
                wav_file.setnchannels(1)
                wav_file.setsampwidth(2)
                wav_file.setframerate(sample_rate)
                wav_file.writeframes(enhanced_audio_int16.tobytes())
            
            logger.info(f"Audio enhanced and saved to: {temp_file_path}")
            return temp_file_path
            
        except Exception as e:
            logger.error(f"Audio enhancement failed: {str(e)}")
            return original_file_path

    def detect_speech_in_audio(self, file_path: str) -> bool:
        """
        Simplified speech detection function for backward compatibility.
        
        Args:
            file_path (str): Path to the audio file.
            
        Returns:
            bool: True if speech is detected, False otherwise.
        """
        try:
            _, has_speech, _ = self.preprocess_audio(file_path)
            return has_speech
        except Exception as e:
            logger.error(f"Speech detection failed: {str(e)}")
            return True  # Fallback to assume speech

    def postprocess_transcription(self, transcription: str, context: str = "") -> str:
        """
        Post-process transcription text for better accuracy.
        
        Args:
            transcription (str): The transcribed text.
            context (str, optional): Additional context for processing.
            
        Returns:
            str: The post-processed transcription text.
        """
        try:
            if not transcription:
                return transcription
                
            # Basic post-processing improvements
            processed_text = transcription.strip()
            
            # Fix common transcription issues
            replacements = {
                # Programming-specific corrections
                "pie torch": "PyTorch",
                "tensorflow": "TensorFlow", 
                "fast API": "FastAPI",
                "pie audio": "PyAudio",
                "num pie": "NumPy",
                "pandas": "pandas",
                "jupiter": "Jupyter",
                "get hub": "GitHub",
                "VS code": "VS Code",
                "docker": "Docker",
                
                # Common speech-to-text errors
                "there": "their",  # Context-dependent, but common in code discussions
                "its": "it's",     # When discussing code functionality
            }
            
            # Apply context-aware replacements
            for wrong, correct in replacements.items():
                processed_text = processed_text.replace(wrong, correct)
            
            # Capitalize first letter of sentences
            sentences = processed_text.split('. ')
            processed_sentences = [s.strip().capitalize() if s else s for s in sentences]
            processed_text = '. '.join(processed_sentences)
            
            logger.info("Transcription post-processing completed")
            return processed_text
            
        except Exception as e:
            logger.error(f"Transcription post-processing failed: {str(e)}")
            return transcription  # Return original on error

    async def enhanced_transcribe_audio(self, file_path: str, context: str = "", 
                                    custom_prompt: str = None) -> Tuple[str, dict]:
        """
        Enhanced transcription with improved preprocessing.
        
        Args:
            file_path (str): Path to the audio file.
            context (str, optional): Additional context for transcription.
            custom_prompt (str, optional): Custom prompt for transcription.
            
        Returns:
            Tuple[str, dict]: A tuple containing the transcription text and analysis results.
        """
        try:
            # Enhanced preprocessing with detailed analysis
            processed_audio_path, has_speech, analysis_results = self.preprocess_audio(file_path)
            
            if not has_speech:
                logger.info("No speech detected - skipping transcription")
                return "", analysis_results
            
            # Proceed with Groq or gemini transcription
            logger.info("Speech detected - proceeding with transcription")
            if initialized_dbs.get_transcription_model() == "whisper":
                transcription = await speech_service.transcribe_audio_whisper(
                    audio_file_path=processed_audio_path,  # Use processed path here
                    custom_prompt=custom_prompt
                )
            elif initialized_dbs.get_transcription_model() == "gemini":
                transcription = await speech_service.transcribe_audio_gemini(
                    audio_file_path=processed_audio_path
                )
            
            # Post-process transcription
            processed_transcription = self.postprocess_transcription(transcription, context)
            
            # Clean up enhanced audio file if it's different from original
            if processed_audio_path != file_path and os.path.exists(processed_audio_path):
                try:
                    os.unlink(processed_audio_path)
                except:
                    pass
            
            logger.info(f"Transcription completed: {len(processed_transcription)} characters")
            return processed_transcription, analysis_results
            
        except Exception as e:
            logger.error(f"Enhanced transcription failed: {str(e)}")
            return "", {"error": str(e)}

    async def enhanced_transcribe_with_context(self, file_path: str, context: str) -> Tuple[str, dict]:
        """
        Enhanced context-aware transcription.
        
        Args:
            file_path (str): Path to the audio file.
            context (str): Context to improve transcription accuracy.
            
        Returns:
            Tuple[str, dict]: A tuple containing the transcription text and analysis results.
        """
        try:
            # Use context to create better prompt
            context_prompt = f"""Previous context: {context}"""            
            return await self.enhanced_transcribe_audio(file_path, context, context_prompt)
            
        except Exception as e:
            logger.error(f"Context-aware transcription failed: {str(e)}")
            # FIXED: Corrected syntax error (removed comma before speech_service)
            fallback_result = await speech_service.transcribe_audio_with_context(file_path, context)
            return fallback_result, {"error": str(e), "fallback_used": True}