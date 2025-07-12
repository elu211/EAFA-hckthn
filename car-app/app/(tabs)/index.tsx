import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Dimensions } from 'react-native';
import { Ionicons } from '@expo/vector-icons';

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

const { width, height } = Dimensions.get('window');

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
      case 'danger': return '#EF4444';
      case 'warning': return '#F59E0B';
      case 'info': return '#3B82F6';
      case 'success': return '#10B981';
      default: return '#6B7280';
    }
  };

  return (
    <View style={styles.container}>
      {/* Status Bar */}
      <View style={styles.statusBar}>
        <View style={styles.statusLeft}>
          <Ionicons name="cellular" size={16} color="white" />
          <Ionicons name="wifi" size={16} color="white" />
          <Text style={styles.statusText}>GPS</Text>
        </View>
        <Text style={styles.timeText}>{currentTime.toLocaleTimeString()}</Text>
        <View style={styles.statusRight}>
          <Ionicons name="battery-full" size={16} color="white" />
          <Text style={styles.statusText}>87%</Text>
        </View>
      </View>

      {/* Main Camera Display */}
      <View style={styles.cameraContainer}>
        {/* Front Camera */}
        <View style={styles.frontCamera}>
          <View style={styles.cameraContent}>
            <Ionicons name="camera" size={64} color="#9CA3AF" />
            <Text style={styles.cameraText}>Front Camera</Text>
            <Text style={styles.cameraSubtext}>1920x1080 • 60fps</Text>
          </View>
        </View>

        {/* Back Camera (Picture-in-Picture) */}
        <View style={styles.rearCamera}>
          <View style={styles.rearCameraContent}>
            <Ionicons name="camera-reverse" size={24} color="#9CA3AF" />
            <Text style={styles.rearCameraText}>Rear</Text>
          </View>
        </View>

        {/* Recording Indicator */}
        {isRecording && (
          <View style={styles.recordingIndicator}>
            <View style={styles.recordingDot} />
            <Text style={styles.recordingText}>REC</Text>
          </View>
        )}

        {/* Speed and Location Overlay */}
        <View style={styles.speedOverlay}>
          <Ionicons name="location" size={16} color="white" />
          <Text style={styles.speedText}>{Math.round(speed)} mph</Text>
        </View>

        {/* Recording Time */}
        {isRecording && (
          <View style={styles.timeOverlay}>
            <Ionicons name="time" size={16} color="white" />
            <Text style={styles.timeText}>{formatTime(recordingTime)}</Text>
          </View>
        )}
      </View>

      {/* AI Alerts Panel */}
      <View style={styles.alertsPanel}>
        <View style={styles.alertsHeader}>
          <Ionicons name="shield-checkmark" size={16} color="#60A5FA" />
          <Text style={styles.alertsTitle}>AI ALERTS</Text>
        </View>
        <View style={styles.alertsList}>
          {alerts.slice(0, 2).map(alert => (
            <View key={alert.id} style={styles.alertItem}>
              <View style={[styles.alertDot, { backgroundColor: getAlertColor(alert.type) }]} />
              <Text style={styles.alertMessage} numberOfLines={1}>{alert.message}</Text>
              <Text style={styles.alertTime}>
                {alert.timestamp.toLocaleTimeString().slice(0, 5)}
              </Text>
            </View>
          ))}
        </View>
      </View>

      {/* Control Panel */}
      <ScrollView style={styles.controlPanel} contentContainerStyle={styles.controlContent}>
        {/* Recording Controls */}
        <View style={styles.recordingControls}>
          <TouchableOpacity
            onPress={toggleRecording}
            style={[
              styles.recordButton,
              isRecording ? styles.recordButtonActive : styles.recordButtonInactive
            ]}
          >
            {isRecording ? (
              <Ionicons name="square" size={32} color="white" />
            ) : (
              <Ionicons name="videocam" size={32} color="black" />
            )}
          </TouchableOpacity>
        </View>

        {/* Camera Selection */}
        <View style={styles.cameraSelection}>
          <Text style={styles.sectionTitle}>Camera Mode</Text>
          <View style={styles.cameraButtons}>
            {['front', 'rear', 'both'].map(mode => (
              <TouchableOpacity
                key={mode}
                onPress={() => setActiveCamera(mode)}
                style={[
                  styles.cameraButton,
                  activeCamera === mode ? styles.cameraButtonActive : styles.cameraButtonInactive
                ]}
              >
                <Text style={[
                  styles.cameraButtonText,
                  activeCamera === mode ? styles.cameraButtonTextActive : styles.cameraButtonTextInactive
                ]}>
                  {mode.charAt(0).toUpperCase() + mode.slice(1)}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* AI Features */}
        <View style={styles.aiFeatures}>
          <Text style={styles.sectionTitle}>AI Features</Text>
          <View style={styles.featuresGrid}>
            {Object.entries(aiFeatures).map(([key, value]) => (
              <TouchableOpacity
                key={key}
                style={styles.featureItem}
                onPress={() => setAiFeatures(prev => ({
                  ...prev,
                  [key]: !value
                }))}
              >
                <View style={[styles.checkbox, value && styles.checkboxChecked]}>
                  {value && <Ionicons name="checkmark" size={12} color="white" />}
                </View>
                <Text style={styles.featureText}>
                  {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>

        {/* Quick Actions */}
        <View style={styles.quickActions}>
          <TouchableOpacity style={styles.actionButton}>
            <Ionicons name="settings" size={20} color="white" />
            <Text style={styles.actionText}>Settings</Text>
          </TouchableOpacity>
          <TouchableOpacity style={styles.emergencyButton}>
            <Ionicons name="warning" size={20} color="white" />
            <Text style={styles.actionText}>Emergency</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>

      {/* Status Footer */}
      <View style={styles.footer}>
        <Text style={styles.footerText}>Storage: 128GB • Available: 89GB • Auto-backup: On</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'black',
  },
  statusBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 8,
    backgroundColor: '#111827',
  },
  statusLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  statusRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  statusText: {
    color: 'white',
    fontSize: 12,
  },
  timeText: {
    color: 'white',
    fontSize: 12,
    fontFamily: 'monospace',
  },
  cameraContainer: {
    height: 320,
    backgroundColor: '#374151',
    borderWidth: 2,
    borderColor: '#4B5563',
    position: 'relative',
  },
  frontCamera: {
    flex: 1,
    backgroundColor: '#1E3A8A',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cameraContent: {
    alignItems: 'center',
  },
  cameraText: {
    color: '#9CA3AF',
    marginTop: 8,
  },
  cameraSubtext: {
    color: '#6B7280',
    fontSize: 12,
    marginTop: 4,
  },
  rearCamera: {
    position: 'absolute',
    top: 16,
    right: 16,
    width: 96,
    height: 64,
    backgroundColor: '#065F46',
    borderWidth: 1,
    borderColor: '#4B5563',
    borderRadius: 4,
    justifyContent: 'center',
    alignItems: 'center',
  },
  rearCameraContent: {
    alignItems: 'center',
  },
  rearCameraText: {
    color: '#9CA3AF',
    fontSize: 12,
    marginTop: 4,
  },
  recordingIndicator: {
    position: 'absolute',
    top: 16,
    left: 16,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  recordingDot: {
    width: 12,
    height: 12,
    backgroundColor: '#EF4444',
    borderRadius: 6,
  },
  recordingText: {
    color: '#EF4444',
    fontFamily: 'monospace',
    fontSize: 14,
  },
  speedOverlay: {
    position: 'absolute',
    bottom: 16,
    left: 16,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    padding: 8,
    borderRadius: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  speedText: {
    color: 'white',
    fontSize: 14,
  },
  timeOverlay: {
    position: 'absolute',
    bottom: 16,
    right: 16,
    backgroundColor: 'rgba(0, 0, 0, 0.5)',
    padding: 8,
    borderRadius: 4,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  alertsPanel: {
    height: 80,
    backgroundColor: '#111827',
    padding: 8,
  },
  alertsHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 4,
  },
  alertsTitle: {
    color: '#60A5FA',
    fontSize: 12,
    fontWeight: '600',
  },
  alertsList: {
    gap: 4,
  },
  alertItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  alertDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
  },
  alertMessage: {
    color: 'white',
    fontSize: 12,
    flex: 1,
  },
  alertTime: {
    color: '#6B7280',
    fontSize: 12,
  },
  controlPanel: {
    flex: 1,
    backgroundColor: '#111827',
  },
  controlContent: {
    padding: 16,
  },
  recordingControls: {
    alignItems: 'center',
    marginBottom: 24,
  },
  recordButton: {
    width: 80,
    height: 80,
    borderRadius: 40,
    justifyContent: 'center',
    alignItems: 'center',
  },
  recordButtonActive: {
    backgroundColor: '#EF4444',
  },
  recordButtonInactive: {
    backgroundColor: 'white',
  },
  cameraSelection: {
    marginBottom: 24,
  },
  sectionTitle: {
    color: 'white',
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 8,
  },
  cameraButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  cameraButton: {
    flex: 1,
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 8,
  },
  cameraButtonActive: {
    backgroundColor: '#2563EB',
  },
  cameraButtonInactive: {
    backgroundColor: '#374151',
  },
  cameraButtonText: {
    textAlign: 'center',
    fontSize: 14,
  },
  cameraButtonTextActive: {
    color: 'white',
  },
  cameraButtonTextInactive: {
    color: 'white',
  },
  aiFeatures: {
    marginBottom: 24,
  },
  featuresGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  featureItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    width: '48%',
  },
  checkbox: {
    width: 16,
    height: 16,
    borderWidth: 1,
    borderColor: '#4B5563',
    borderRadius: 2,
    justifyContent: 'center',
    alignItems: 'center',
  },
  checkboxChecked: {
    backgroundColor: '#2563EB',
    borderColor: '#2563EB',
  },
  featureText: {
    color: 'white',
    fontSize: 14,
  },
  quickActions: {
    flexDirection: 'row',
    gap: 12,
  },
  actionButton: {
    flex: 1,
    backgroundColor: '#374151',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  emergencyButton: {
    flex: 1,
    backgroundColor: '#D97706',
    paddingVertical: 12,
    paddingHorizontal: 16,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  actionText: {
    color: 'white',
    fontSize: 14,
  },
  footer: {
    backgroundColor: '#1F2937',
    padding: 8,
    alignItems: 'center',
  },
  footerText: {
    color: '#9CA3AF',
    fontSize: 12,
  },
});

export default AIDashcamApp;