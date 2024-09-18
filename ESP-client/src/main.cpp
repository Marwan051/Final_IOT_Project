#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <Arduino.h>
#include <DHT.h>
#include <Adafruit_Sensor.h>
#include <LiquidCrystal_I2C.h>
#include <Keypad.h>
#include <ESP32Servo.h>

// WiFi and HiveMQ Cloud credentials
const char *ssid = "Marwan's Galaxy A23";                                        // Your Wi-Fi SSID (use Wokwi for simulation)
const char *password = "smbe6756";                                               // Wokwi doesn't require a password
const char *mqtt_server = "b68b626745dd4b16b1352e00c3c031ed.s1.eu.hivemq.cloud"; // HiveMQ Cloud broker URL
const int mqtt_port = 8883;                                                      // Secure MQTT port for HiveMQ Cloud

// MQTT credentials for HiveMQ Cloud
const char *mqtt_user = "publish_user"; // HiveMQ Cloud username
const char *mqtt_password = "Aaaa4444"; // HiveMQ Cloud password

// Secure Wi-Fi client
WiFiClientSecure espClient;
PubSubClient client(espClient);

// MQTT topic
const char *sensor_topic = "sensor/total_score";
const char *debug_gas_topic = "debug/sensor/alarm";
// Sensor readings (to be updated with actual sensor values)
int final_score = 0;

// pin definitions

// Pin Definitions for Sensors
#define DHTPIN 15     // Pin connected to the DATA pin of DHT11
#define DHTTYPE DHT11 // DHT 11 (AM2302) type
DHT dht(DHTPIN, DHTTYPE);

#define GAS_SENSOR_PIN 35 // GPIO pin connected to the gas sensor's analog output
#define BUZZER_PIN 23     // GPIO pin connected to the buzzer
#define MQ135_PIN 34      // GPIO pin 34 for analog readings
#define SERVO_PIN 18      // GPIO pin connected to the servo motor

unsigned long previousTime = millis() - 60000; // Store the last time the event was triggered
const unsigned long interval = 6000;           // 1 minute in milliseconds

int displayMode = 1;                     // Variable to track the current display mode (1, 2, or 3)
unsigned long modeSwitchTime = 0;        // Timer to switch modes every second
const unsigned long modeInterval = 6000; // 1 second for mode switch interval
float temperature = 0.0;
float humidity = 0.0;
float airQualityScore = 0.0;
// LCD Setup
LiquidCrystal_I2C lcd(0x27, 16, 2); // Set the LCD address to 0x27 for a 16 chars, 2 line display

int gasLevel = 0;       // Variable to store the gas level
float gasVoltage = 0.0; // Variable to store the gas sensor voltage
// Keypad Setup
const byte ROWS = 4; // Four rows
const byte COLS = 4; // Four columns
char keys[ROWS][COLS] = {
    {'1', '2', '3', 'A'},
    {'4', '5', '6', 'B'},
    {'7', '8', '9', 'C'},
    {'*', '0', '#', 'D'}};
byte rowPins[ROWS] = {32, 33, 25, 26}; // Connect to the row pinouts of the keypad
byte colPins[COLS] = {27, 14, 12, 13}; // Connect to the column pinouts of the keypad

Keypad keypad = Keypad(makeKeymap(keys), rowPins, colPins, ROWS, COLS);

String keypadPassword = "1234"; // Set the correct password
String inputPassword = "";      // Variable to store the input from the keypad
bool accessGranted = false;     // Flag to indicate if access is granted
bool debugMode = false;
// Servo Setup
Servo myServo;

void setup_wifi()
{
  delay(10);
  Serial.begin(115200);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, password);

  while (WiFi.status() != WL_CONNECTED)
  {
    delay(500);
    Serial.print(".");
  }

  Serial.println("");
  Serial.println("WiFi connected");
}

void reconnect()
{
  while (!client.connected())
  {
    Serial.print("Attempting MQTT connection...");
    // Connect using username and password
    if (client.connect("ESP32Client", mqtt_user, mqtt_password))
    {
      Serial.println("Connected to HiveMQ Cloud");
      // Subscribe to the debug topics
      client.subscribe("debug/mode");
      client.subscribe("debug/finalScore");
      client.subscribe("debug/gas");
    }
    else
    {
      Serial.print("Failed, rc=");
      Serial.print(client.state());
      Serial.println(" Try again in 5 seconds");
      delay(5000);
    }
  }
}

void publish_combined_data()
{
  if (!client.connected())
  {
    reconnect();
  }

  // Combine sensor readings into a list format
  String sensorData = String(final_score);

  // Publish the sensor data as a string to the topic
  if (client.publish(sensor_topic, sensorData.c_str()))
  {
    Serial.println("Combined sensor data published:");
    Serial.println(sensorData);
  }
  else
  {
    Serial.println("Sensor data publishing failed");
  }
}

// MQTT callback function
void callback(char *topic, byte *payload, unsigned int length)
{
  String message;
  for (unsigned int i = 0; i < length; i++)
  {
    message += (char)payload[i];
  }
  Serial.println("Message arrived on topic: " + String(topic));
  if (String(topic) == "debug/mode")
  {
    int msg = message.toInt();
    if (msg == 1)
    {
      debugMode = true;
      Serial.println("Entering debug mode");
    }
    else
    {
      debugMode = false;
      Serial.println("Exiting debug mode");
    }
  }
  else if (String(topic) == "debug/finalScore")
  {
    if (debugMode)
    {
      final_score = message.toInt();
    }
  }
  else if (String(topic) == "debug/gas")
  {
    if (debugMode)
    {
      gasVoltage = message.toFloat();
    }
  }
}

void setup()
{
  Serial.begin(115200);
  setup_wifi();

  // Set .setInsecure() to bypass SSL certificate validation
  espClient.setInsecure(); // Using this instead of a CA certificate

  client.setServer(mqtt_server, mqtt_port); // Set the MQTT server and port
  client.setCallback(callback);             // Set the MQTT callback function

  // Subscribe to the debug topics
  client.subscribe("debug/mode");
  client.subscribe("debug/finalScore");
  client.subscribe("debug/gas");
  // Initialize sensors here
  pinMode(BUZZER_PIN, OUTPUT); // Set the buzzer pin as output
  pinMode(MQ135_PIN, INPUT);   // Set MQ-135 pin as input

  dht.begin(); // Initialize DHT sensor
  pinMode(DHTPIN, INPUT);

  // Initialize the LCD
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Enter Password:");

  // Initialize Servo
  myServo.attach(SERVO_PIN); // Attach the servo to the defined pin
  myServo.write(0);          // Set servo to initial position (0 degrees)
}

void loop()
{
  if (!client.connected())
  {
    reconnect();
  }

  client.loop();

  // Read sensor values
  if (!accessGranted)
  {
    char key = keypad.getKey(); // Read the key pressed from the keypad

    if (key)
    {
      if (key == '#')
      { // '#' is used to submit the password
        if (inputPassword == keypadPassword)
        {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Access Granted");
          delay(1000);
          lcd.clear();
          accessGranted = true; // Unlock the system
        }
        else
        {
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Wrong Password");
          delay(1000);
          lcd.clear();
          lcd.setCursor(0, 0);
          lcd.print("Enter Password:");
          inputPassword = ""; // Reset the input password
        }
      }
      else if (key == '*')
      { // '' is used to clear the input
        inputPassword = "";
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Enter Password:");
      }
      else
      {
        inputPassword += key; // Append the pressed key to the input password
        lcd.setCursor(0, 1);
        lcd.print(inputPassword); // Show the input on the LCD
      }
    }
    return; // Do not run the main program until access is granted
  }

  // Main program starts here after access is granted
  unsigned long currentTime = millis(); // Get the current time in milliseconds

  // Check if 1 minute (60000 ms) has passed
  if (currentTime - previousTime >= interval)
  {
    previousTime = currentTime; // Update the stored time to the current time

    // Read temperature and humidity from DHT11 sensor
    humidity = dht.readHumidity();
    temperature = dht.readTemperature();

    // Calculate Temperature and Humidity Scores
    float tempDiff = abs(temperature - 21);
    float tempScore = map(tempDiff, 0, 29, 100, 0);
    float HumDiff = abs(humidity - 40);
    Serial.print("Humidity Difference: ");
    Serial.println(HumDiff);
    float HumScore = map(HumDiff, 0, 40, 100, 0);

    // Read analog value from the MQ-135 sensor
    int airQualityValue = analogRead(MQ135_PIN);
    Serial.print("Air Quality Value: ");
    Serial.println(airQualityValue);
    airQualityScore = map(airQualityValue, 0, 4095, 100, 0);
    Serial.print("Air Quality Score: ");
    Serial.println(airQualityScore);
    // Control Servo Motor based on the average score (Temperature, Humidity, Air Quality)
    if (!debugMode)
    {
      Serial.print("Temperature Score: ");
      Serial.println(tempScore);
      Serial.print("Humidity Score: ");
      Serial.println(HumScore);
      Serial.print("Air Quality Score: ");
      Serial.println(airQualityScore);
      final_score = (int)(tempScore + HumScore + airQualityScore) / 3;
    }
    int servoPosition = map(final_score, 0, 100, 0, 180); // Map score to servo angle
    myServo.write(servoPosition);
    Serial.print("Servo Position: ");
    Serial.println(servoPosition);
    // Publish combined sensor data every 5 seconds
    publish_combined_data();
  }

  if (!debugMode)
  {
    // Gas Detection Logic
    gasLevel = analogRead(GAS_SENSOR_PIN);
    gasVoltage = gasLevel * (3.3 / 4095.0);
    Serial.print("Gas Sensor Voltage: ");
    Serial.println(gasVoltage);
  }
  // Automatically switch display modes every 1 second
  if (currentTime - modeSwitchTime >= modeInterval)
  {
    modeSwitchTime = currentTime;        // Update the mode switch time
    displayMode = (displayMode % 3) + 1; // Cycle between modes 1 and 2
    lcd.clear();
  }

  // Display data based on the current mode
  switch (displayMode)
  {
  case 2:
    lcd.setCursor(0, 0);
    lcd.print("Temp: ");
    lcd.print(temperature);
    lcd.setCursor(0, 1);
    lcd.print("Humidity: ");
    lcd.print(humidity);
    break;
  case 1:
    lcd.setCursor(0, 0);
    lcd.print("Air quality");
    lcd.setCursor(0, 1);
    lcd.print("Score: ");
    lcd.print(airQualityScore);
    lcd.setCursor(0, 1);
    break;
  case 3:
    lcd.setCursor(0, 0);
    lcd.print("Final Score: ");
    lcd.setCursor(0, 1);
    lcd.print(final_score);
    break;
  }

  if (gasVoltage > 1.5)
  { // Adjust threshold as necessary
    Serial.println("Gas detected!");
    digitalWrite(BUZZER_PIN, HIGH);
  }
  else
  {
    Serial.println("No gas detected.");
    digitalWrite(BUZZER_PIN, LOW);
  }

  delay(1000); // Wait for 1 second before reading again
}