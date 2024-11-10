#include <MIDI.h> 

#define LED 13
MIDI_CREATE_DEFAULT_INSTANCE();

int BTN_lecOLD = digitalRead(2);
int cChannel, vValue, cCVal;


void setup() {
  pinMode (2, INPUT_PULLUP);
  pinMode (LED, OUTPUT); // Set Arduino board pin 13 to output
  MIDI.begin (MIDI_CHANNEL_OMNI);
  Serial.begin (115200); // Initialize the Midi Library.
  BTN_lecOLD = digitalRead(2);
}


void loop() {
    
  MIDI.read(); 
  cCVal = MIDI.getData1();
  vValue = MIDI.getData2();
  cChannel = MIDI.getChannel();
  Serial.print("cCVal: ");
  Serial.print(cCVal);
  Serial.print("\n");
  Serial.print("vValue: ");
  Serial.print(vValue);
  Serial.print("\n");
  Serial.print("cChannel: ");
  Serial.print(cChannel);
  Serial.print("\n");
  delay(100);

int BTNlec = digitalRead(2);
if (BTNlec == LOW && BTN_lecOLD == HIGH){
BTN_lecOLD = BTNlec;
MIDI.sendControlChange(cCVal, vValue, cChannel);
//Serial.println(cCVal); 
digitalWrite(LED,HIGH);
delay(10);
}else if(BTNlec == HIGH && BTN_lecOLD == LOW){
if (BTN_lecOLD != BTNlec){
BTN_lecOLD = BTNlec;
MIDI.sendControlChange(cCVal, vValue, cChannel);
digitalWrite(LED,LOW);
delay(10);}
}

}

