import React, { useState, useEffect } from 'react';
import { Camera, Video, Square, Settings, AlertTriangle, Shield, MapPin, Clock, Battery, Wifi, Signal } from 'lucide-react';

// Define types for better type safety
interface Alert {
  id: number;
  type: 'danger' | 'warning' | 'info' | 'success';
  message: string;
  timestamp: Date;
}

interface AIFeatures {
  laneDetection: boolean;
  collisionWarning: boolean;
  speedLimit: boolean;
  parkingMode: boolean;
}

const AIDashcamApp = () => {
  const [isRecording, setIsRecording] = useState(false);
  const [activeCamera, setActiveCamera] = useState('both');
  const [recordingTime, setRecordingTime] = useState(0);
  const [currentTime, setCurrentTime] = useState(new Date());
  const [speed, setSpeed] = useState(0);
  const [alerts, setAlerts] = useState<Alert[]>([]);
  const [aiFeatures, setAiFeatures] = useState<AIFeatures>({
    laneDetection: true,
    collisionWarning: true,
    speedLimit: true,
    parkingMode: false
  });

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
      if (isRecording) {
        setRecordingTime(prev => prev + 1);
      }
    }, 1000);

    // Simulate speed updates
    const speedTimer = setInterval(() => {
      setSpeed(prev => Math.max(0, prev + (Math.random() - 0.5) * 10));
    }, 2000);

    return () => {
      clearInterval(timer);
      clearInterval(speedTimer);
    };
  }, [isRecording]);

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;
    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const toggleRecording = () => {
    if (isRecording) {
      setIsRecording(false);
      setRecordingTime(0);
    } else {
      setIsRecording(true);
    }
  };

  const addAlert = (type: Alert['type'], message: string) => {
    const newAlert: Alert = {
      id: Date.now(),
      type,
      message,
      timestamp: new Date()
    };
    setAlerts(prev => [newAlert, ...prev.slice(0, 4)]);
  };

  // Simulate AI alerts
  useEffect(() => {
    if (isRecording) {
      const alertTimer = setInterval(() => {
        const alertTypes: Array<{ type: Alert['type']; message: string }> = [
          { type: 'warning', message: 'Lane departure detected' },
          { type: 'danger', message: 'Forward collision risk' },
          { type: 'info', message: 'Speed limit: 65 mph' },
          { type: 'success', message: 'Parking mode activated' }
        ];
        
        if (Math.random() < 0.3) {
          const randomAlert = alertTypes[Math.floor(Math.random() * alertTypes.length)];
          addAlert(randomAlert.type, randomAlert.message);
        }
      }, 5000);

      return () => clearInterval(alertTimer);
    }
  }, [isRecording]);

  const getAlertColor = (type: Alert['type']) => {
    switch (type) {
      case 'danger': return 'bg-red-500';
      case 'warning': return 'bg-yellow-500';
      case 'info': return 'bg-blue-500';
      case 'success': return 'bg-green-500';
      default: return 'bg-gray-500';
    }
  };

  return (
    <div className="min-h-screen bg-black text-white overflow-hidden">
      {/* Status Bar */}
      <div className="flex justify-between items-center p-2 bg-gray-900 text-xs">
        <div className="flex items-center gap-2">
          <Signal className="w-4 h-4" />
          <Wifi className="w-4 h-4" />
          <span>GPS</span>
        </div>
        <div className="font-mono">{currentTime.toLocaleTimeString()}</div>
        <div className="flex items-center gap-1">
          <Battery className="w-4 h-4" />
          <span>87%</span>
        </div>
      </div>

      {/* Main Camera Display */}
      <div className="relative h-80 bg-gray-800 border-2 border-gray-700">
        {/* Front Camera */}
        <div className="absolute inset-0 bg-gradient-to-br from-blue-900 to-gray-900 flex items-center justify-center">
          <div className="text-center">
            <Camera className="w-16 h-16 mx-auto mb-2 text-gray-400" />
            <p className="text-gray-400">Front Camera</p>
            <p className="text-xs text-gray-500">1920x1080 • 60fps</p>
          </div>
        </div>

        {/* Back Camera (Picture-in-Picture) */}
        <div className="absolute top-4 right-4 w-24 h-16 bg-gradient-to-br from-green-900 to-gray-900 border border-gray-600 rounded flex items-center justify-center">
          <div className="text-center">
            <Camera className="w-6 h-6 mx-auto text-gray-400" />
            <p className="text-xs text-gray-400">Rear</p>
          </div>
        </div>

        {/* Recording Indicator */}
        {isRecording && (
          <div className="absolute top-4 left-4 flex items-center gap-2">
            <div className="w-3 h-3 bg-red-500 rounded-full animate-pulse"></div>
            <span className="text-red-500 font-mono text-sm">REC</span>
          </div>
        )}

        {/* Speed and Location Overlay */}
        <div className="absolute bottom-4 left-4 bg-black bg-opacity-50 p-2 rounded">
          <div className="flex items-center gap-2 text-sm">
            <MapPin className="w-4 h-4" />
            <span>{Math.round(speed)} mph</span>
          </div>
        </div>

        {/* Recording Time */}
        {isRecording && (
          <div className="absolute bottom-4 right-4 bg-black bg-opacity-50 p-2 rounded">
            <div className="flex items-center gap-2 text-sm font-mono">
              <Clock className="w-4 h-4" />
              <span>{formatTime(recordingTime)}</span>
            </div>
          </div>
        )}
      </div>

      {/* AI Alerts Panel */}
      <div className="h-20 bg-gray-900 p-2 overflow-hidden">
        <div className="flex items-center gap-2 mb-1">
          <Shield className="w-4 h-4 text-blue-400" />
          <span className="text-xs font-semibold text-blue-400">AI ALERTS</span>
        </div>
        <div className="space-y-1">
          {alerts.slice(0, 2).map(alert => (
            <div key={alert.id} className="flex items-center gap-2 text-xs">
              <div className={`w-2 h-2 rounded-full ${getAlertColor(alert.type)}`}></div>
              <span className="truncate">{alert.message}</span>
              <span className="text-gray-500 ml-auto">
                {alert.timestamp.toLocaleTimeString().slice(0, 5)}
              </span>
            </div>
          ))}
        </div>
      </div>

      {/* Control Panel */}
      <div className="flex-1 bg-gray-900 p-4">
        {/* Recording Controls */}
        <div className="flex justify-center items-center gap-6 mb-6">
          <button
            onClick={toggleRecording}
            className={`w-20 h-20 rounded-full flex items-center justify-center transition-all duration-300 ${
              isRecording 
                ? 'bg-red-500 hover:bg-red-600 shadow-lg shadow-red-500/50' 
                : 'bg-white hover:bg-gray-100 shadow-lg'
            }`}
          >
            {isRecording ? (
              <Square className="w-8 h-8 text-white" />
            ) : (
              <Video className="w-8 h-8 text-black" />
            )}
          </button>
        </div>

        {/* Camera Selection */}
        <div className="mb-6">
          <p className="text-sm font-semibold mb-2">Camera Mode</p>
          <div className="flex gap-2">
            {['front', 'rear', 'both'].map(mode => (
              <button
                key={mode}
                onClick={() => setActiveCamera(mode)}
                className={`flex-1 py-2 px-4 rounded-lg transition-all ${
                  activeCamera === mode
                    ? 'bg-blue-600 text-white'
                    : 'bg-gray-700 hover:bg-gray-600'
                }`}
              >
                {mode.charAt(0).toUpperCase() + mode.slice(1)}
              </button>
            ))}
          </div>
        </div>

        {/* AI Features */}
        <div className="mb-6">
          <p className="text-sm font-semibold mb-2">AI Features</p>
          <div className="grid grid-cols-2 gap-3">
            {Object.entries(aiFeatures).map(([key, value]) => (
              <label key={key} className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={value}
                  onChange={(e) => setAiFeatures(prev => ({
                    ...prev,
                    [key]: e.target.checked
                  }))}
                  className="w-4 h-4 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500"
                />
                <span className="text-sm">
                  {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                </span>
              </label>
            ))}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="flex gap-3">
          <button className="flex-1 bg-gray-700 hover:bg-gray-600 py-3 px-4 rounded-lg flex items-center justify-center gap-2 transition-colors">
            <Settings className="w-5 h-5" />
            <span className="text-sm">Settings</span>
          </button>
          <button className="flex-1 bg-yellow-600 hover:bg-yellow-700 py-3 px-4 rounded-lg flex items-center justify-center gap-2 transition-colors">
            <AlertTriangle className="w-5 h-5" />
            <span className="text-sm">Emergency</span>
          </button>
        </div>
      </div>

      {/* Status Footer */}
      <div className="bg-gray-800 p-2 text-xs text-center text-gray-400">
        Storage: 128GB • Available: 89GB • Auto-backup: On
      </div>
    </div>
  );
};

export default AIDashcamApp;