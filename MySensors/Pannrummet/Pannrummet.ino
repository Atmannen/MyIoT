#include <SPI.h>
#include <MySensor.h>  
#include <NewPing.h>

#define CHILD_ID 1
#define CHILD_ID_LIGHT_FAULT 2
#define CHILD_ID_LIGHT_PELLET 3
#define LIGHT_SENSOR_DIGITAL_PIN_FAULT 8
#define LIGHT_SENSOR_DIGITAL_PIN_PELLET 7
#define TRIGGER_PIN  6  // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN     5  // Arduino pin tied to echo pin on the ultrasonic sensor.
#define MAX_DISTANCE 300 // Maximum distance we want to ping for (in centimeters). Maximum sensor distance is rated at 400-500cm.
#define SLEEP_MODE false
unsigned long SEND_FREQUENCY = 60000; // Sleep time between reads (in milliseconds)

MySensor gw;
NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.
MyMessage sonarMsg(CHILD_ID, V_DISTANCE);
MyMessage faultMsg(CHILD_ID_LIGHT_FAULT, V_TRIPPED);
MyMessage pelletMsg(CHILD_ID_LIGHT_PELLET, V_LIGHT_LEVEL);
MyMessage pcMsg(CHILD_ID_LIGHT_PELLET,V_VAR1);
int lastDist;
bool lastLightLevel_Fault;
bool lastLightLevel_Pellet;
boolean pcReceived = false;
volatile unsigned long pelletCount = 0;   
unsigned long oldPelletCount = 0; 
boolean metric = true; 
unsigned long lastSend;

void setup()  
{ 
  gw.begin(incomingMessage);
  // Initialize library and add callback for incoming messages

  // Send the sketch version information to the gateway and Controller
  gw.sendSketchInfo("Sonar and Lights for Pellet", "1.0");

  // Register all sensors to gw (they will be created as child devices)
  gw.present(CHILD_ID, S_DISTANCE);
  gw.present(CHILD_ID_LIGHT_FAULT, S_MOTION);
  gw.present(CHILD_ID_LIGHT_PELLET, S_CUSTOM);
  // Fetch last known pulse count value from gw
  gw.request(CHILD_ID_LIGHT_PELLET, V_VAR1);
  boolean metric = gw.getConfig().isMetric;
  lastSend=millis();
}

void loop()      
{     
  gw.process();
  unsigned long now = millis();
  bool sendTime = now - lastSend > SEND_FREQUENCY;
  if (pcReceived && (SLEEP_MODE || sendTime)) {
    int dist = metric?sonar.ping_cm():sonar.ping_in();
    Serial.print("Ping: ");
    Serial.print(dist); // Convert ping time to distance in cm and print result (0 = outside set distance range)
    Serial.println(metric?" cm":" in");
  
    if (dist != lastDist) {
        gw.send(sonarMsg.set(dist));
        lastDist = dist;
    }
    bool lightLevelFault = !digitalRead(LIGHT_SENSOR_DIGITAL_PIN_FAULT);
    Serial.print("FaultLed: "); 
    Serial.println(lightLevelFault);
    if (lightLevelFault != lastLightLevel_Fault) {
        gw.send(faultMsg.set(lightLevelFault));
        lastLightLevel_Fault = lightLevelFault;
    }
    
    bool lightLevelPellet = !digitalRead(LIGHT_SENSOR_DIGITAL_PIN_PELLET); 
    Serial.print("PelletLed: ");   
    Serial.println(lightLevelPellet);
    if (lightLevelPellet != lastLightLevel_Pellet) {
        if (lightLevelPellet == true){
          pelletCount++;
          gw.send(pcMsg.set(pelletCount));
          oldPelletCount = pelletCount;
 
        }
        lastLightLevel_Pellet = lightLevelPellet;
        
    }
    lastSend = now;
  } else if (sendTime && !pcReceived) {
    // No count received. Try requesting it again
    Serial.print("No pelletCount Received...\n"); 
    gw.request(CHILD_ID_LIGHT_PELLET, V_VAR1);
  }
  if (SLEEP_MODE) {
  gw.sleep(SEND_FREQUENCY);
  }
}

void incomingMessage(const MyMessage &message) {
  if (message.type==V_VAR1 && !pcReceived) {  
    pelletCount = oldPelletCount = message.getLong();
    Serial.print("Received last pellet count from gw:");
    Serial.println(pelletCount);
    pcReceived = true;
  }
}


