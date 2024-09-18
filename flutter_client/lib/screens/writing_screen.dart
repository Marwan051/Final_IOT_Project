import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';

class WritingScreen extends StatefulWidget {
  const WritingScreen({super.key});

  @override
  WritingScreenState createState() => WritingScreenState();
}

class WritingScreenState extends State<WritingScreen> {
  final String _broker = 'b68b626745dd4b16b1352e00c3c031ed.s1.eu.hivemq.cloud';
  final String _clientId = 'flutter_client';
  final String _finalScoreTopic = 'debug/finalScore';
  final String _gasLevelTopic = 'debug/gas';
  final String _debugTopic = 'debug/mode';

  late MqttServerClient _client;
  final TextEditingController _finalScoreController = TextEditingController();
  final TextEditingController _gasLevelController = TextEditingController();
  bool _isConnected = false;
  bool _isConnecting = true;

  @override
  void initState() {
    super.initState();
    _initializeMqttClient();
  }

  Future<void> _initializeMqttClient() async {
    _client = MqttServerClient(_broker, _clientId)
      ..port = 8883
      ..secure = true
      ..onDisconnected = _onDisconnected
      ..onSubscribed = _onSubscribed;

    try {
      await _client.connect('subscribe_user', 'Aaaa4444');
      log('MQTT client connected');
      _sendDebugMessage(1); // Send debug message when connected
      setState(() {
        _isConnected = true;
        _isConnecting = false;
      });
    } catch (e) {
      log('MQTT connection error: $e');
      setState(() {
        _isConnecting = false;
      });
    }

    _client.updates!.listen(_onMessageReceived);
  }

  void _sendDebugMessage(int status) {
    final builder = mqtt.MqttClientPayloadBuilder();
    builder.addString(status.toString());
    _client.publishMessage(
        _debugTopic, mqtt.MqttQos.exactlyOnce, builder.payload!);
  }

  void _onDisconnected() {
    log('Disconnected');
    _sendDebugMessage(0); // Send debug message when disconnected
    setState(() {
      _isConnected = false;
    });
  }

  void _onSubscribed(String topic) {
    log('Subscribed to $topic');
  }

  void _onMessageReceived(
      List<mqtt.MqttReceivedMessage<mqtt.MqttMessage>> messages) {
    final mqtt.MqttPublishMessage message =
        messages[0].payload as mqtt.MqttPublishMessage;
    final payload =
        mqtt.MqttPublishPayload.bytesToStringAsString(message.payload.message);

    log('Received message: $payload');
    // Handle received messages if needed
  }

  void _sendFinalScore() {
    String finalScoreText = _finalScoreController.text;

    if (finalScoreText.isNotEmpty) {
      final builder = mqtt.MqttClientPayloadBuilder();
      builder.addString(finalScoreText);
      _client.publishMessage(
          _finalScoreTopic, mqtt.MqttQos.exactlyOnce, builder.payload!);
      _finalScoreController.clear(); // Clear text field after sending
    }
  }

  void _sendGasLevel() {
    String gasLevelText = _gasLevelController.text;

    if (gasLevelText.isNotEmpty) {
      final builder = mqtt.MqttClientPayloadBuilder();
      builder.addString(gasLevelText);
      _client.publishMessage(
          _gasLevelTopic, mqtt.MqttQos.exactlyOnce, builder.payload!);
      _gasLevelController.clear(); // Clear text field after sending
    }
  }

  @override
  void dispose() {
    _sendDebugMessage(0); // Send debug message when leaving the screen
    _client.disconnect();
    _finalScoreController.dispose();
    _gasLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor Reading Screen'),
      ),
      body: _isConnecting
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  TextField(
                    controller: _finalScoreController,
                    decoration:
                        const InputDecoration(labelText: 'Final Score (float)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        _isConnected && _finalScoreController.text.isNotEmpty
                            ? _sendFinalScore
                            : null,
                    child: const Text('Send Final Score'),
                  ),
                  TextField(
                    controller: _gasLevelController,
                    decoration:
                        const InputDecoration(labelText: 'Gas Level (float)'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed:
                        _isConnected && _gasLevelController.text.isNotEmpty
                            ? _sendGasLevel
                            : null,
                    child: const Text('Send Gas Level'),
                  ),
                ],
              ),
            ),
    );
  }
}
