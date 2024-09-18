#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <time.h> // Include the time library
// Replace with your network credentials
const char *ssid = "Wokwi-GUEST";
const char *wifiPassword = "";
const char *mqtt_server = "b68b626745dd4b16b1352e00c3c031ed.s1.eu.hivemq.cloud"; // HiveMQ Cloud broker URL
const int mqtt_port = 8883;                                                      // Secure MQTT port for HiveMQ Cloud

// MQTT credentials for HiveMQ Cloud
const char *mqtt_user = "extra_user";   // HiveMQ Cloud username
const char *mqtt_password = "Aaaa4444"; // HiveMQ Cloud password

// MQTT topic to subscribe to
const char *sensor_topic = "sensor/total_score";

// Secure Wi-Fi client
WiFiClientSecure espClient;
PubSubClient client(espClient);

// Replace with your Firebase project credentials
const char *FIREBASE_PROJECT_ID = "final-project-iot-fb03b";
#define FIREBASE_API_KEY "AIzaSyC0Kp2Him5zrS7ZM3eoAe9v_Xu4Vxg7KLg"
#define FIREBASE_AUTH_DOMAIN "final-project-iot-fb03b.firebaseapp.com"
String db_url = "https://final-project-iot-fb03b.firebaseio.com";
FirebaseJson data;

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;
// Function to get the current time as an ISO 8601 string
String getISO8601Timestamp()
{
  time_t now;
  struct tm timeinfo;
  char buffer[25];

  time(&now);
  localtime_r(&now, &timeinfo);
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);

  return String(buffer);
}

// Function to handle incoming messages
void callback(char *topic, byte *message, unsigned int length)
{
  Serial.print("Message arrived on topic: ");
  Serial.println(topic);

  String messageTemp;

  for (int i = 0; i < length; i++)
  {
    messageTemp += (char)message[i];
  }

  Serial.print("Message: ");
  Serial.println(messageTemp);

  // Extracting sensor values from the list format (e.g., "[25.6,70.3,40.8,1012.5]")
  messageTemp.trim();           // Remove any extra spaces or newlines
  messageTemp.replace("[", ""); // Remove '[' character
  messageTemp.replace("]", ""); // Remove ']' character

  int total_score = 0;

  // Parse sensor values
  sscanf(messageTemp.c_str(), "%i", &total_score);

  // Print sensor values
  Serial.println("Parsed score value:");
  Serial.print("Total Score: ");
  Serial.println(total_score);
  // Set Firebase credentials
  FirebaseConfig firebaseConfig;
  firebaseConfig.api_key = FIREBASE_API_KEY;
  firebaseConfig.database_url = db_url;
  FirebaseAuth firebaseAuth;
  firebaseAuth.user.email = "testuser@test.com";
  firebaseAuth.user.password = "Aaaa4444";
  Firebase.begin(&firebaseConfig, &firebaseAuth);
  Firebase.reconnectNetwork(true);
  // Prepare data with timestamp
  FirebaseJson data;
  String timestamp = String(millis()); // Use millis() for timestamp; replace with NTP for real-time
  Serial.print("Time now is ");
  Serial.println(getISO8601Timestamp());
  data.set("fields/timestamp/timestampValue", getISO8601Timestamp().c_str());
  data.set("fields/score/doubleValue", total_score);

  // Convert FirebaseJson to String
  String jsonString;
  data.toString(jsonString, true);

  // Create document with auto-generated ID
  String path = "total_score"; // Changed to collection path
  if (Firebase.Firestore.createDocument(&fbdo, FIREBASE_PROJECT_ID, "", path.c_str(), jsonString.c_str()))
  {
    Serial.println("Data sent successfully");
  }
  else
  {
    Serial.println("Failed to send data");
    Serial.println(fbdo.errorReason());
  }
}

void setup_wifi()
{
  Serial.begin(115200);
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.begin(ssid, wifiPassword);

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
    if (client.connect("ESP32Server", mqtt_user, mqtt_password))
    {
      Serial.println("Connected to HiveMQ Cloud");
      client.subscribe(sensor_topic); // Subscribe to the topic after connecting
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

void setup()
{
  Serial.begin(115200);
  Serial.println("Starting Firebase setup");
  setup_wifi();
  // Initialize time
  Serial.print("Getting time");
  configTime(0, 0, "pool.ntp.org", "time.nist.gov"); // UTC-3 offset (-3 hours in seconds)

  // Wait for time to be set
  while (time(nullptr) < 8 * 3600 * 2)
  {
    Serial.print(".");
    delay(1000);
  }
  Serial.println("Time synchronized");
  Serial.print("Time now is: ");
  Serial.println(getISO8601Timestamp());
  espClient.setInsecure();
  client.setServer(mqtt_server, mqtt_port);
  client.setKeepAlive(60000);
  client.setCallback(callback);
}

void loop()
{
  if (!client.connected())
  {
    reconnect();
  }

  client.loop();
}